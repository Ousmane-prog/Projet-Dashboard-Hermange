module App

include("lib/SIModel.jl")  # Include the file with your SIS model implementation
using Turing, MCMCChains, GenieFramework, DifferentialEquations, PlotlyBase, StippleLatex, StatsPlots, Random, PrettyTables, DataFrames
using .SIModel
Random.seed!(14)

@genietools

@app begin
    @out isLoading = false
    # Define reactive variables for the SIS model
    @in beta = 0.52
    @in gamma = 0.24
    @in noise_level = 0.3  # Noise level for synthetic data

    # Plot for ODE solutions
    @out solplot = []  
    @out solplot_layout = PlotlyBase.Layout(
        title="SI Model Simulation",
        xaxis_title="Time",
        yaxis_title="Population",
        template="plotly_white"
    )
    @out data_plot = []
    @out data_plot_layout = PlotlyBase.Layout(
        title="Synthetic Data",
        xaxis_title="Time",
        yaxis_title="Population",
        template="plotly_white"
    )
    @private u0 = [0.99, 0.01]  # Initial conditions for S and Iusing Pkg
    @private tspan = (0.0, 100.0)  # Time span for the simulation
    @private t = 0.0:1.0:100.0  # Time points for solution
    @private true_p = [0.52, 0.24]

    # React to changes in beta and gamma
    @onchange beta, gamma begin
        try
            # Validate parameters
            if beta <= 0 || gamma <= 0
                error("Beta and Gamma must be positive.")
            end

            # Solve the ODE problem
            p = [beta, gamma]
            prob = ODEProblem(SIModel.SIS!, u0, tspan, p)
            sol = solve(prob, Tsit5())

            # Update the plot
            solplot = [
                PlotlyBase.scatter(x=sol.t, y=sol[1, :], mode="lines", name="Susceptible"),
                PlotlyBase.scatter(x=sol.t, y=sol[2, :], mode="lines", name="Infected")
            ]
        catch e
            println("Error solving ODE: ", e)
        end
    end  
    
    # Bayesian inference results
    @out summary_string = ""  
    @out bayesian_plot_beta = []  
    @out bayesian_plot_layout_beta = PlotlyBase.Layout(
        title="Posterior Distributions of Beta",
        xaxis_title="Beta",
        template="plotly_white",
        yaxis_title="Frequency",
    )
    @out bayesian_plot_gamma = []  
    @out bayesian_plot_layout_gamma = PlotlyBase.Layout(
        title="Posterior Distribution of Gamma",
        xaxis_title="Gamma",
        template="plotly_white",
        yaxis_title="Frequency",
    )
    
    
    @out chain_plot = []  
    @out chain_plot_layout = PlotlyBase.Layout(
        title="Trace Plots of Parameters",
        xaxis_title="Iterations",
        yaxis_title="Value",
        template="plotly_white"
    )
    # Perform Bayesian inference when noise_level changes
    @onchange noise_level begin
        try

            isLoading = true
            global noisy_data, sol2, prob

            prob = SIModel.create_SIS_problem(u0, tspan, true_p)
            noisy_data, sol2 = SIModel.generate_synthetic_data(prob, Tsit5(), t, noise_level)
            # println("-----------------------------------------------------------------------------")
            # println("Noisy data generated: ")
            data_plot = [
                PlotlyBase.scatter(x=sol2.t, y=noisy_data[1, :], name="Susceptible (nosiy)", mode="markers", color = "red"),
                PlotlyBase.scatter(x=sol2.t, y=noisy_data[2, :],name="Infected (nosiy)", mode="markers", color = "blue"),
                PlotlyBase.scatter(x=sol2.t, y=sol2[1, :], mode="lines", name="Susceptible", color = "red"),
                PlotlyBase.scatter(x=sol2.t, y=sol2[2, :], mode="lines", name="Infected", color = "blue")
            ]
        catch e
            println("Error generating synthetic data: ", e)

        end

        try
            global model = SIModel.fitsi(noisy_data, prob)
        catch e
            println("Error during model creation: ", e, " | Inputs: noisy_data: ", noisy_data, " | prob: ", prob)
        end
            
            # model = SIModel.fitsi(SIModel.generate_synthetic_data(SIModel.create_SIS_problem(u0, tspan, true_p), Tsit5(), t, noise_level), SIModel.create_SIS_problem(u0, tspan, true_p))
        try
            
            global chain = sample(model, NUTS(), MCMCSerial(), 1000, 3; progress=false)
            if isempty(chain)
                println("Empty chain returned.")
            end
            println("type of chain is ", typeof(chain))
        catch e
            println("Error during sampling: ", e)
        end

        try
            
            global beta_mean
            global gamma_mean
            global beta_std
            global gamma_std
            global beta_mcse
            global gamma_mcse
            global beta_ess_bulk
            global gamma_ess_bulk
            global beta_ess_tail
            global gamma_ess_tail
            

            beta_mean = round(mean(chain[:beta]), digits=2)
            gamma_mean = round(mean(chain[:gamma]), digits=2)
            beta_std = round(std(chain[:beta]), digits=2)
            gamma_std = round(std(chain[:gamma]), digits=2)
            beta_mcse = round(mcse(chain[:beta]), digits=2)
            gamma_mcse = round(mcse(chain[:gamma]), digits=2)
            beta_ess_bulk = round(ess(chain[:beta], mode=:bulk), digits=2)
            gamma_ess_bulk = round(ess(chain[:gamma], mode=:bulk), digits=2)
            beta_ess_tail = round(ess(chain[:beta], mode=:tail), digits=2)
            gamma_ess_tail = round(ess(chain[:gamma], mode=:tail), digits=2)

        catch e
            println("Error during summary statistics: ", e)
        end

        try
            global posterior_samples = Array(chain)
        
            # beta_rhat = round(rhat(chain[:beta]), digits=2)
            # gamma_rhat = round(rhat(chain[:gamma]), digits=2)

            # chain plot
            # try
            #     # Assuming `chain` has been sampled successfully:
            #     global iter_count
            #     iter_count = size(posterior_samples, 1)
            #     chain_plot = [
            #         PlotlyBase.scatter(
            #             x=1:iter_count, 
            #             y=posterior_samples[:, i], 
            #             mode="lines", 
            #             name=string("Chain_", i)
            #         ) for i in 1:3
            #     ]
            # catch e
            #     println("Error updating chain plot: ", e)
            # end
            bayesian_plot_beta = [
                PlotlyBase.histogram(x=posterior_samples[:, 1], opacity=0.75, nbinsx=30),
            ]
            bayesian_plot_gamma = [ 
                PlotlyBase.histogram(x=posterior_samples[:, 2], opacity=0.75, nbinsx=30)
            ]
            
        catch e
            println("Error during Bayesian inference: ", e)
        finally
            isLoading = false
        end

    end
end  

meta = Dict(
    "og:title" => "SI Model Simulation",
    "og:description" => "Real-time simulation of an SI epidemic model with adjustable parameters and Bayesian inference.",
    "og:image" => "/preview.jpg"
)

layout = DEFAULT_LAYOUT(meta=meta)
@page("/", "app.jl.html", layout; core_theme=true)

end
