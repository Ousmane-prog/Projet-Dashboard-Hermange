module App

include("lib/SIModel.jl")  # Include the file with your SIS model implementation
using Turing, MCMCChains, GenieFramework, DifferentialEquations, PlotlyBase, StippleLatex, ModelingToolkit, StatsPlots, Random
using .SIModel
Random.seed!(14)

# noisy_data = CSV.File("noisy_data.csv") |> DataFrame

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
    @private true_p = [0.52, 0.24]
    # React to changes in beta and gamma
    @onchange beta, gamma begin
        try
            # Define parameters for infection and recovery rates
            p = [beta, gamma]

            # Define and solve the ODE problem
           
            prob = ODEProblem(SIModel.SIS!, u0, tspan, p)
            
            # noisy_data, sol = SiModel.generate_noisy_data(prob, Tsit5(), t, noise_level)
            sol = solve(prob, Tsit5())

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
    
    @out summary_string = ""  
    @out bayesian_plot = []  # Initialize with an empty array for PlotData
    @out layout = PlotlyBase.Layout(
        title="Posterior Distributions",
        xaxis_title="Parameter Value",
        yaxis_title="Density",
        template="plotly_white"
    )
    println("Bayesian plot layout initialized")
    

    #  Perform Bayesian inference when the user requests it
    @onchange noise_level begin
        try
            # Define true parameters for synthetic data generation

            # Generate synthetic noisy data
            prob = SIModel.create_SIS_problem(u0, tspan, true_p)
            
            println("Problem created ", prob)
            noisy_data = SIModel.generate_synthetic_data(prob, Tsit5(), t, noise_level)
            println("--------------------------------------------")
            println("Noisy data: ", noisy_data)

            # Perform Bayesian inference
            model = SIModel.fitsi(noisy_data, prob)
            chain = sample(model, NUTS(), MCMCThreads(), 1000, 3; progress=false)

            # Summarize the results
            chain_summary = describe(chain)

            # Prepare summary statistics for display
            beta_summary = chain_summary["beta", :]
            gamma_summary = chain_summary["gamma", :]

         
            # Visualize the posterior distributions (simplified example)
            bayesian_plot = [
                PlotlyBase.histogram(x=chain[:beta], name="Posterior of Beta", opacity=0.75),
                PlotlyBase.histogram(x=chain[:gamma], name="Posterior of Gamma", opacity=0.75)
            ]
        catch e
            println("Error during Bayesian inference: ", e)
        end
    end
end  

meta = Dict(
    "og:title" => "SI Model Simulation",
    "og:description" => "Real-time simulation of an SI epidemic model with adjustable parameters and Parameter estimation using Turing.jl package.",
    "og:image" => "/preview.jpg"
)

layout = DEFAULT_LAYOUT(meta=meta)
@page("/", "app.jl.html", layout)
end
