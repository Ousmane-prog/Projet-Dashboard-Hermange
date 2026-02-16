#!/bin/bash
# SI Model Dashboard - Production Startup Script
# This script starts the Genie web application with proper configuration

set -e

# Load environment variables from .env if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set defaults if not provided
HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8000}
JULIA_ENV=${JULIA_ENV:-production}
APP_ENV=${APP_ENV:-production}

echo "│ SI Model Dashboard - Deployment Starting..."
echo "├─ Environment: $APP_ENV"
echo "├─ Host: $HOST"
echo "├─ Port: $PORT"
echo "└─ Julia env: $JULIA_ENV"
echo ""

# Export configuration for Julia
export JULIA_ENV
export HOST
export PORT
export APP_ENV

# Run the application
echo "Starting application..."
julia --project -e "
    using Genie
    
    # Configure Genie for the environment
    println(\"Loading application...\")
    
    # Include the app
    include(\"app.jl\")
    
    # Start the server
    println(\"\\nStarting Genie server on \$(@__ENV__[\"HOST\"]):\$(@__ENV__[\"PORT\"])\")
    Genie.Server.up(host=\"\$(@__ENV__[\"HOST\"])\", port=parse(Int, \$(@__ENV__[\"PORT\"])), async=false)
"
