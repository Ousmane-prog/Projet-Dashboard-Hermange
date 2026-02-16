# SI Model Dashboard - Production Dockerfile
# Multi-stage build for optimized image size

FROM julia:1.12-bookworm as builder

WORKDIR /app

# Copy project files
COPY Project.toml Manifest.toml ./
COPY lib/ lib/
COPY app.jl app.jl.html ./
COPY bin/ bin/

# Install Julia dependencies
RUN julia --project -e 'using Pkg; Pkg.instantiate()'

# Precompile packages to speed up startup
RUN julia --project -e 'using Pkg; Pkg.precompile()'


# Production stage
FROM julia:1.12-bookworm

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy from builder
COPY --from=builder /app /app
COPY --from=builder /root/.julia /root/.julia

# Create log directory
RUN mkdir -p log

# Create non-root user for security
RUN useradd -m -s /bin/bash appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port (configurable via environment)
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD julia --project -e "using HTTP; HTTP.get(\"http://localhost:8000\", status_exception=false)" || exit 1

# Default environment variables
ENV JULIA_ENV=production \
    HOST=0.0.0.0 \
    PORT=8000

# Run the application
CMD ["julia", "--project", "bin/run.jl"]
