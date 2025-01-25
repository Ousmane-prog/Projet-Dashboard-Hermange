module App

include("lib/SIModel.jl")
using GenieFramework, DifferentialEquations, Turing, PlotlyBase
using .SiModel
@genietools



@app begin
    # Define reactive variables for the SIS model
    @in beta = 0.5  # Default infection rate
    @in gamma = 0.1 # Default recovery rate
    # @in S0 = 0.99    # Initial susceptible population
    # @in I0 = 0.01    # Initial infected population

    # Placeholder for the simulation results (will be updated by the model)
    @out solplot = PlotData()
    @out layout = PlotLayout(
        xaxis=[PlotLayoutAxis(xy="x", title="Time")],
        yaxis=[PlotLayoutAxis(xy="y", title="Population")],
        title="SI Model",
        showlegend=true

    )

    @private u_x = []  # Time vector
    @private u_S = []  # Susceptible population
    @private u_I = []  # Infected population

    @onchange(beta, gamma) begin
        # Define initial conditions
        u0 = [0.99, 0.01]  # Initial susceptible and infected populations
        p = [beta, gamma]  # Parameters for infection and recovery rates
        tspan = (0.0, 100.0)

        # Define the ODE problem
        prob = ODEProblem(SIModel.SIS!, u0, tspan, p)

        # Solve the ODE
        sol = solve(prob, Tsit5())

        # # Update the plot data
        # solplot = PlotData(x=sol.t, y=sol[1], plot=PlotlyBase.PlotType.Line, name="Susceptible")
        # solplot2 = PlotData(x=sol.t, y=sol[2], plot=PlotlyBase.PlotType.Line, name="Infected")
        solplot = [
            PlotData(x=sol.t, y=sol[1], plot=PlotlyBase.PlotType.Line, name="Susceptible", mode="lines"),
            PlotData(x=sol.t, y=sol[2], plot=PlotlyBase.PlotType.Line, name="Infected", mode="lines")
        ]
        # Store the results for future access
        # u_x = sol.t
        # u_S = sol[1]
        # u_I = sol[2]
    end
end

meta = Dict("og:title" => "Lorenz Chaotic Attractor",
    "og:description" => "Real-time simulation of a dynamic system with constant UI refresh.",
    "og:image" => "/preview.jpg")

layout = DEFAULT_LAYOUT(meta=meta)
@page("/", "app.jl.html", layout)
end

