module SIModel

using DifferentialEquations, Turing, PlotlyBase, MCMCChains, Random 


export SIS!, create_SIS_problem, generate_synthetic_data, fitsi

# Define the SIS! function
function SIS!(dN, N, p, t)
    S = N[1]
    I = N[2]
    beta = p[1]
    gamma = p[2]
    
    dN[1] = -(beta * S * I) + gamma * I   
    dN[2] = (beta * S * I) - gamma * I    
    
end

# Generate noisy data function
# function generate_noisy_data(prob, solver=Tsit5(), saveat, noise_level)
#     sol = solve(prob, solver; saveat=saveat)
#     odedata = Array(sol)
#     noisy_data = odedata .+ noise_level * randn(size(odedata))
#     return noisy_data, sol
# end

# Function to create an ODE problem for the SIS model
function create_SIS_problem(N0, tspan, p)
    try
        # println("Creating ODEProblem with initial conditions: ", N0)
        # println("Time span: ", tspan)
        # println("Parameters: ", p)

        # Create the ODEProblem
        prob = ODEProblem(SIS!, N0, tspan, p)

        # Check the created problem object
        # println("ODEProblem created: ", prob)
        
        # Ensure that the prob is not nothing
        if prob === nothing
            error("ODEProblem creation failed.")
        end

        return prob
    catch e
        println("Error while creating the ODEProblem: ", e)
    end
end




# Function to generate synthetic data by solving the ODE and adding noise
function generate_synthetic_data(prob, solver, t, noise_level)
    sol = solve(prob, solver, saveat=t)
    noisy_d = Array(sol) + noise_level * randn(size(Array(sol)))

    # println("Synthetic data generated ", noisy_d[1, :])
    return noisy_d
end

# @model function fitsi(data, prob)
#     # Priors for parameters
#     beta ~ Uniform(0, 10)
#     gamma ~ Uniform(0, 10)

#     # Solve the ODE with sampled parameters
#     p = [beta, gamma]
#     predicted = solve(prob, Tsit5(), p=p, saveat=0.1)
#     println("----------------------------------------------------")
#     println("Predicted: ", predicted)
#     predicted_array = Array(predicted)

#     # Likelihood
#     for i in 1:size(data, 2)
#         data[:, i] ~ MvNormal(predicted_array[:, i], 0.4)
#     end
# end
@model function fitsi(data, prob)
    beta ~ Uniform(0, 10)
    gamma ~ Uniform(0, 10)
    
    p = [beta, gamma]
    println("----------------------------------------------------")
    println("Parameters: ", p)
    predicted = solve(prob, Tsit5(), p=p, saveat=0.1)
    println("\n***********************Prediction done successfully*******************\n: ")

    # for i in eachindex(data, 2)  # Loop over the second dimension (time points)
    #     data[:, i] ~ MvNormal(predicted[:, i], 0.4)
    # end
    for i in 1:size(data, 2)  # Loop over time points
        data[:, i] ~ MvNormal(predicted[:, i], 0.4)
    end
end


end