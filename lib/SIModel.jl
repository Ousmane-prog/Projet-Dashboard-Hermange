module SiModel

using DifferentialEquations
using Turing
using PlotlyBase

export SIS!, generate_noisy_data

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
function generate_noisy_data(prob, solver, saveat, noise_level)
    sol = solve(prob, solver; saveat=saveat)
    odedata = Array(sol)
    noisy_data = odedata .+ noise_level * randn(size(odedata))
    return noisy_data, sol
end

end # module

