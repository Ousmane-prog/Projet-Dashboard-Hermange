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

# Function to create an ODE problem for the SIS model
function create_SIS_problem(N0, tspan, p)
    try
        # Create the ODEProblem
        prob = ODEProblem(SIS!, N0, tspan, p)

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
    return noisy_d, sol
end

@model function fitsi(data, prob)
    beta ~ Uniform(0, 10)
    gamma ~ Uniform(0, 10)
    
    p = [beta, gamma]
    
    predicted = solve(prob, Tsit5(), p=p, saveat=0.1)

    for i in 1:size(data, 2)  # Loop over time points
        data[:, i] ~ MvNormal(predicted[:, i], 0.4)
    end
end


end