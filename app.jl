module App

include("lib/SIModel.jl")  # Include the file with your SIS model implementation
using GenieFramework, DifferentialEquations, PlotlyBase, StippleLatex, ModelingToolkit, StatsPlots, Random, DataFrames, CSV
using .SIModel
Random.seed!(14)

noisy_data = CSV.File("noisy_data.csv") |> DataFrame
@genietools

@app begin
    # Define reactive variables for the SIS model
    @in beta = 0.52
    @in gamma = 0.24
    @in noise_level = 0.3  # Noise level for the data

    # Rendering the plot
    @out solplot = []  # Initialize with an empty array for PlotData
    @out layout = PlotlyBase.Layout(
        title="SI Model Simulation",
        xaxis_title="Time",
        yaxis_title="Population",
        template="plotly_white"
    )
    
    @private u0 = [0.99, 0.01]  # Initial conditions for S and I
    @private tspan = (0.0, 100.0)  # Time span for the simulation
    @private t = 0.0:1.0:100.0  # Time points for solution
    @private theme = :light  # Theme for the app

    # React to changes in beta and gamma
    @onchange beta, gamma begin
        try
            # Define parameters for infection and recovery rates
            p = [beta, gamma]

            # Define and solve the ODE problem
            # prob = ODEProblem(SiModel.SIS!, u0, tspan, p)
            prob = ODEProblem(SIModel.SIS!, u0, tspan, p)
            # noisy_data, sol = SiModel.generate_noisy_data(prob, Tsit5(), t, noise_level)
            sol = solve(prob, Tsit5())
            # x = sol.t
            # y1= sol[1]
            # y2 = sol[2]
            # println("x ", x)
            # println("y ", y1)
            # println("y2 ", y2)
            println("----------------------------------------------------------------------")
            println("Dimensions of sol ", size(sol))
            println("sol ", sol)
            

            # Update the plot data with susceptible and infected populations
            solplot = [
                
                PlotlyBase.scatter(x=sol.t, y=sol[1,:], mode="lines", name="Susceptible"),
                PlotlyBase.scatter(x=sol.t, y=sol[2,:], mode="lines", name="Infected")
                # PlotlyBase.scatter(x=sol.t, y=noisy_data[1], mode="markers", marker_size=4),
                # PlotlyBase.scatter(x=sol.t, y=noisy_data[2], mode="markers", marker_size=4)
            ]
        catch e
            println("Error encountered while solving ODE: ", e)
            println("Parameters: beta = $beta, gamma = $gamma, u0 = $u0, tspan = $tspan")
        end
    end  
end  

meta = Dict(
    "og:title" => "SIS Model Simulation",
    "og:description" => "Real-time simulation of an SIS epidemic model with adjustable parameters.",
    "og:image" => "/preview.jpg"
)

layout = DEFAULT_LAYOUT(meta=meta)
@page("/", "app.jl.html", layout)

end
