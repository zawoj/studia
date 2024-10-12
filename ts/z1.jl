using DifferentialEquations
using Plots

# Parametry
μ = 1.0
tspan = (0.0, 20.0)
u0 = [2.0, 0.0]

# Funkcja dla równania van der Pola
function van_der_pol!(du, u, p, t)
    du[1] = u[2]
    du[2] = μ * (1 - u[1]^2) * u[2] - u[1]
end

# Rozwiązanie równania
prob = ODEProblem(van_der_pol!, u0, tspan)
sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

# Wizualizacja wyników
plot(sol, 
     xlabel="t", 
     ylabel="x₁, x₂", 
     label=["x₁" "x₂"],
     linewidth=2,
     title="Równanie van der Pola")

# Zapisanie wykresu
savefig("van_der_pol.png")

# Modyfikacja równania z jawną zależnością od czasu
function modified_van_der_pol!(du, u, p, t)
    du[1] = u[2] + sin(t)
    du[2] = μ * (1 - u[1]^2) * u[2] - u[1] + 2cos(t)
end

# Rozwiązanie zmodyfikowanego równania
mod_prob = ODEProblem(modified_van_der_pol!, u0, tspan)
mod_sol = solve(mod_prob, Tsit5(), reltol=1e-8, abstol=1e-8)

# Wizualizacja wyników zmodyfikowanego równania
plot(mod_sol, 
     xlabel="t", 
     ylabel="x₁, x₂", 
     label=["x₁" "x₂"],
     linewidth=2,
     title="Zmodyfikowane równanie van der Pola")

# Zapisanie wykresu
savefig("modified_van_der_pol.png")