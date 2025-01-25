module App

include("lib/SIModel.jl")  # Include the file with your SIS model implementation
using GenieFramework, DifferentialEquations, PlotlyBase, StippleLatex, ModelingToolkit, StatsPlots
using .SiModel



@genietools

# function SIS!(dN, N, p, t)
#     S = N[1]
#     I = N[2]
#     beta = p[1]
#     gamma = p[2]
    
#     dN[1] = -(beta * S * I) + gamma * I   
#     dN[2] = (beta * S * I) - gamma * I    
end

@app begin
    # Define reactive variables for the SIS model
    @in beta = 0.5  
    @in gamma = 0.1 

     # rendering the plot
    @out solplot = [sacatter(x=[])]
    @out layout = PlotlyBase.Layout(title="SI Model Simulation", xaxis_title="Time", yaxis_title="Population")
    
    @private u0 = [99, 10]  
    @private tspan = (0.0, 100.0)
    @private t = 0.0:1.0:100.0
    @private theme = :light 
    # React to changes in beta and gamma
    @onchange beta, gamma begin
        # Define initial conditions
        p = [beta, gamma]  # Parameters for infection and recovery rates

        prob = ODEProblem(SiModel.SIS!, u0, tspan, p, dt=0.1, adaptive=true)

        # Solve the ODE
        # sol = solve(prob, Tsit5())
        sol = solve(prob, Tsit5(), saveat=t)
        # println("sol  at time steps:", sol.t[1:5])
        # println("sol values:", sol[1:5])

        # Update the plot data with both susceptible and infected populations
        solplot = [
            PlotData(x=sol.t, y=sol[1], plot=PlotlyBase.PlotType.Line, name="Susceptible", mode="lines",),
            PlotData(x=sol.t, y=sol[2], plot=PlotlyBase.PlotType.Line, name="Infected", mode="lines")
        ]
        # solplot = [plot(sol, label=["S" "I"], lw=2)]
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
