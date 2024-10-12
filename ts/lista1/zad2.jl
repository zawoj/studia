using DifferentialEquations
using Plots

# Parametry obwodu
R = 3.0
L = 1.0
C = 1/2

# Funkcja źródła napięcia
u(t) = exp(-2t)

# Funkcja dla układu równań RLC
function rlc!(du, u, p, t)
    vc, i = u
    du[1] = i / C
    du[2] = -(R/L)*i - (1/L)*vc + (1/L)*exp(-2t)
end

# Warunki początkowe i przedział czasu
u0 = [0.0, 0.0]  # [vc(0), i(0)]
tspan = (0.0, 5.0)

# Rozwiązanie numeryczne
prob = ODEProblem(rlc!, u0, tspan)
sol = solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

# Przygotowanie danych do wykresu
t = range(tspan[1], tspan[2], length=500)
vc_num = [sol(ti)[1] for ti in t]
i_num = [sol(ti)[2] for ti in t]

# Wizualizacja wyników
p1 = plot(t, vc_num, label="vc", linewidth=2, color=:blue)
xlabel!("Czas")
ylabel!("Napięcie na kondensatorze")
title!("Napięcie na kondensatorze w obwodzie RLC")

p2 = plot(t, i_num, label="i", linewidth=2, color=:red)
xlabel!("Czas")
ylabel!("Natężenie prądu")
title!("Natężenie prądu w obwodzie RLC")

plot(p1, p2, layout=(2,1), size=(800,600))
savefig("rlc_circuit_numerical.png")

# Wypisanie kilku przykładowych wartości
println("Przykładowe wartości:")
for ti in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
    vc, i = sol(ti)
    println("t = $ti: vc = $vc, i = $i")
end