include("DiscretizationMethods.jl")
using .DiscretizationMethods
using ControlSystems
using Plots
using LinearAlgebra
using Polynomials

# Create plots directory if it doesn’t exist
plot_dir = joinpath(pwd(), "plots/c1.3")
mkpath(plot_dir)

# Define systems
G1_s = tf([1], [1, 3])           # 1 / (s + 3)
G2_s = tf([1, 1], [1, 2, 3])    # (s + 1) / (s^2 + 2s + 3)
G3_s = tf([1, 2], [1, 2, 1, 1]) # (s + 2) / (s^3 + 2s^2 + s + 1)

systems = [(G1_s, "1st"), (G2_s, "2nd"), (G3_s, "3rd")]

# Sampling periods
T_values = [0.5, 0.1, 0.01]  # fs = 2 Hz, 10 Hz, 100 Hz

# Input signals
function generate_input(t, type::String)
  n = length(t)
  if type == "step"
    return ones(1, n)  # Matrix: 1 row, n columns
  elseif type == "impulse"
    return [1.0 zeros(1, n - 1)]  # Matrix with impulse at t=0
  elseif type == "ramp"
    return reshape(t, 1, n)  # Reshape t into a 1×n matrix
  else
    error("Unknown input type: $type")
  end
end

input_types = ["step", "impulse", "ramp"]

# Function to analyze poles and stability
function analyze_discretization(Gz, method_name, T, system_name)
  poles_z = pole(Gz)
  mag_poles = abs.(poles_z)
  stable = all(mag_poles .< 1.0 - 1e-6)
  println("$method_name (T = $T, $system_name):")
  println("  Poles: ", round.(poles_z, digits=4))
  println("  Magnitude of poles: ", round.(mag_poles, digits=4))
  println("  Stable: ", stable ? "Yes" : "No")
end

# Generalized Impulse Invariant method for any order
function impulse_invariant_general(G::TransferFunction, T::Float64)
  sys_ss = ss(G)
  A, B, C, D = sys_ss.A, sys_ss.B, sys_ss.C, sys_ss.D
  Ad = exp(A * T)
  Bd = (A \ (Ad - I)) * B
  return tf(ss(Ad, Bd, C, D, T))
end

# Main analysis loop
for (G_s, sys_name) in systems
  println("\nAnalyzing $sys_name")

  for T in T_values
    println("\nSampling period T = $T (fs = $(1/T) Hz):")

    # Discretize using each method
    Gz_impulse = isa(G_s.den, Polynomial) && degree(G_s.den) == 1 ? impulse_invariant(G_s, T) : impulse_invariant_general(G_s, T)
    Gz_zoh = zero_order_hold(G_s, T)
    Gz_foh = c2d(G_s, T, :foh)

    # Analyze stability
    analyze_discretization(Gz_impulse, "Impulse Invariant", T, sys_name)
    analyze_discretization(Gz_zoh, "ZOH", T, sys_name)
    analyze_discretization(Gz_foh, "FOH", T, sys_name)

    # Time responses for different inputs
    t = 0:T:5
    for input_type in input_types
      u = generate_input(t, input_type)
      y_cont = lsim(G_s, u, t).y[1, :]
      y_impulse = lsim(Gz_impulse, u, t).y[1, :]
      y_zoh = lsim(Gz_zoh, u, t).y[1, :]
      y_foh = lsim(Gz_foh, u, t).y[1, :]

      # Plot response
      plt = plot(t, y_cont, label="Continuous", title="$sys_name - $input_type Response (T = $T)", lw=2)
      plot!(t, y_impulse, label="Impulse Invariant", lw=2)
      plot!(t, y_zoh, label="ZOH", lw=2)
      plot!(t, y_foh, label="FOH", lw=2)
      xlabel!("Time (s)")
      ylabel!("Output")
      display(plt)
      savefig(plt, joinpath(plot_dir, "c1_3_$(replace(sys_name, "/"=>"_")).png"))
    end
  end
end

println("\nSummary:")
println("Analysis complete for all systems, inputs, and sampling periods.")
println("Plots saved in 'plots' directory.")