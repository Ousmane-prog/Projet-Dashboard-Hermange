#!/usr/bin/env julia
# SI Model Dashboard - Julia Production Startup Script
# Direct Julia execution without bash wrapper

# Load environment variables
if isfile(".env")
    for line in readlines(".env")
        if !isempty(strip(line)) && !startswith(strip(line), "#")
            key, value = split(line, "=", limit=2)
            ENV[strip(key)] = strip(value, '"')
        end
    end
end

# Set configuration from environment
const HOST = get(ENV, "HOST", "0.0.0.0")
const PORT = parse(Int, get(ENV, "PORT", "8000"))
const APP_ENV = get(ENV, "APP_ENV", "production")
const JULIA_ENV = get(ENV, "JULIA_ENV", "production")

println("┌─────────────────────────────────────────────────────┐")
println("│ SI Model Dashboard - Production Server")
println("├─────────────────────────────────────────────────────┤")
println("│ Environment: $(APP_ENV)")
println("│ Julia Env:   $(JULIA_ENV)")
println("│ Host:        $(HOST)")
println("│ Port:        $(PORT)")
println("└─────────────────────────────────────────────────────┘")
println("")

# Ensure project is activated
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Create log directory if it doesn't exist
isdir("log") || mkdir("log")

# Start logging
using Logging
logfile = "log/app_$(Dates.format(Dates.now(), "yyyy-mm-dd_HH-MM-SS")).log"
io = open(logfile, "w+")
global_logger(SimpleLogger(io, Logging.Warn))

println("Logs will be written to: $(logfile)")
println("")

try
    # Include and run the app
    println("Loading application...")
    include("app.jl")
    
    println("\n✓ Application loaded successfully!")
    println("✓ Server is running...")
    
    # Server will run indefinitely
catch e
    println("ERROR: Failed to start application")
    println(e)
    rethrow(e)
finally
    # Cleanup
    close(io)
end
