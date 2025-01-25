module SIModel

using DifferentialEquations
using Turing
using PlotlyBase

export SIS!
# generate_noisy_data

# Define the SIS! function
function SIS!(dN, N, p, t)
    S = N[1]
    I = N[2]
    beta = p[1]
    gamma = p[2]
    
    dN[1] = -(beta * S * I) + gamma * I   
    dN[2] = (beta * S * I) - gamma * I    
    # println("At time $t, dN = ", dN)
end

# Generate noisy data function
# function generate_noisy_data(prob, solver=Tsit5(), saveat, noise_level)
#     sol = solve(prob, solver; saveat=saveat)
#     odedata = Array(sol)
#     noisy_data = odedata .+ noise_level * randn(size(odedata))
#     return noisy_data, sol
# end

@model function fitsi(data, prob)
    beta ~ Uniform(0, 10)
    gamma ~ Uniform(0, 10)

    N0 = [0.99, 0.01]
    tspan = (0.0, 100.0)
    p = [beta, gamma]
    # predicted = solve(prob, Tsit5(), p=p, saveat=t)
    predicted = solve(prob, Tsit5(), p=p, saveat= 0.1)

    for i in 1:length(predicted)
        data[:,i] ~ MvNormal(predicted[i], 0.4)
    end
end
end # module

