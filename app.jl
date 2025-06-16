module App

include("lib/SIModel.jl")  
using Turing, MCMCChains, GenieFramework, DifferentialEquations, PlotlyBase, StippleLatex, StatsPlots, Random
using .SIModel
Random.seed!(14)

@genietools

@app begin
    # Define reactive variables 
    @in beta = 0.52
    @in gamma = 0.24
    @in noise_level = 0.3  

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
    @out beta_mean = 0.0
    @out gamma_mean = 0.0
    @out beta_std = 0.0
    @out gamma_std = 0.0
    @out beta_mcse = 0.0
    @out gamma_mcse = 0.0
    @out beta_ess_bulk = 0.0
    @out gamma_ess_bulk = 0.0
    @out beta_ess_tail = 0.0
    @out gamma_ess_tail = 0.0
    # @out summary_stats = 0

    @private u0 = [0.99, 0.01]  
    @private tspan = (0.0, 100.0)  
    @private t = 0.0:1.0:100.0  # Time points for solution
    @private true_p = [0.52, 0.24]

    # ode visualization
    @onchange beta, gamma begin
        try
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

            # isLoading = true
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
            global model
            model = SIModel.fitsi(noisy_data, prob)
        catch e
            println("Error during model creation: ", e, " | Inputs: noisy_data: ", noisy_data, " | prob: ", prob)
        end
            
            # model = SIModel.fitsi(SIModel.generate_synthetic_data(SIModel.create_SIS_problem(u0, tspan, true_p), Tsit5(), t, noise_level), SIModel.create_SIS_problem(u0, tspan, true_p))
        try
            println("Starting Bayesian inference...")
            global chain = sample(model, NUTS(), MCMCThreads(), 1000, 3; progress=false)
            println("Sampling complete. Chain: ", typeof(chain))
        catch e
            println("Error during sampling: ", e)
        end

        try        
            # summary_stats, _ = describe(chain)
            beta_mean = round(mean(chain[:beta]), digits=2)
            gamma_mean = round(mean(chain[:gamma]), digits=2)
            beta_std = round(std(chain[:beta]), digits=2)
            gamma_std = round(std(chain[:gamma]), digits=2)
            # beta_mcse = round(mcse(chain[:beta]), digits=2)
            # gamma_mcse = round(mcse(chain[:gamma]), digits=2)
            # beta_ess_bulk = round(ess(chain[:beta], mode=:bulk), digits=2)
            # gamma_ess_bulk = round(ess(chain[:gamma], mode=:bulk), digits=2)
            # beta_ess_tail = round(ess(chain[:beta], mode=:tail), digits=2)
            # gamma_ess_tail = round(ess(chain[:gamma], mode=:tail), digits=2)

        catch e
            println("Error during summary statistics: ", e)
        end

        try
            global posterior_samples = Array(chain)

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
            # isLoading = false
        end

    end
end  

meta = Dict(
    "og:title" => "SI Model Simulation",
    "og:description" => "Real-time simulation of an SI epidemic model with adjustable parameters and Bayesian inference.",
    "og:image" => "/preview.jpg"
)

layout = DEFAULT_LAYOUT(meta=meta)
@page("/", "app.jl.html", layout)

end