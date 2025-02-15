# SI Model Simulation and Parameter Estimation App

## 📌 Description
This web-based application simulates the **Susceptible-Infected (SI) model** and performs **Bayesian parameter estimation** using **Genie.jl** and **Turing.jl**.  
The app allows users to:
- Adjust **epidemic model parameters** interactively.
- Visualize **ODE solutions** for the SI model.
- Generate **synthetic data** with noise.
- Perform **Bayesian inference** using Markov Chain Monte Carlo (MCMC).
- View **posterior distributions** and summary statistics.

## 🚀 Features
- 🏃 **Real-time ODE simulation** with adjustable `β` (infection rate) and `γ` (recovery rate).
- 📊 **Interactive plots** for epidemic dynamics and synthetic data.
- 🤖 **Bayesian inference with Turing.jl** to estimate parameters from noisy observations.
- 🎛️ **Dynamic UI** powered by **GenieFramework**.
- 🛠️ **MCMC sampling** and **posterior analysis**.

## 🛠️ Technologies Used
- **Julia** (Genie.jl, Turing.jl, DifferentialEquations.jl, PlotlyBase.jl, StatsPlots.jl)
- **GenieFramework** for web-based interactivity.
- **Markov Chain Monte Carlo (MCMC)** for Bayesian inference.
- **Plotly.js** for visualization.
