include("DiscretizationMethods.jl")
using .DiscretizationMethods
using ControlSystems
using Plots
using LinearAlgebra  # For norm in stability check

# Create plots directory if it doesn’t exist
plot_dir = joinpath(pwd(), "plots/c1.1")
mkpath(plot_dir)  # Creates the directory if it doesn't exist

# Define the continuous system G(s) = 1 / (s^2 + 1)
G_s = tf([1], [1, 0, 1])

# Sampling periods to test
T_values = [1, 0.5, 0.1, 0.01]  # fs = 2 Hz, 10 Hz, 100 Hz

# Function to analyze poles and stability
function analyze_discretization(Gz, method_name, T)
  poles_z = pole(Gz)
  mag_poles = abs.(poles_z)
  stable = all(mag_poles .< 1.0 - 1e-6)  # Strictly stable
  marginally_stable = all(mag_poles .<= 1.0 + 1e-6) && any(mag_poles .>= 1.0 - 1e-6)
  println("$method_name (T = $T):")
  println("  Poles: ", round.(poles_z, digits=4))
  println("  Magnitude of poles: ", round.(mag_poles, digits=4))
  println("  Stable: ", stable ? "Yes" : "No")
  println("  Marginally Stable: ", marginally_stable ? "Yes" : "No")
  return poles_z
end

# Main analysis loop
for T in T_values
  println("\nSampling period T = $T (fs = $(1/T) Hz):")

  # Forward Euler
  Gz_forward = forward_euler(G_s, T)
  forward_poles = analyze_discretization(Gz_forward, "Forward Euler", T)

  # Backward Euler
  Gz_backward = backward_euler(G_s, T)
  backward_poles = analyze_discretization(Gz_backward, "Backward Euler", T)

  # Tustin’s Method
  Gz_tustin = tustin_method(G_s, T)
  tustin_poles = analyze_discretization(Gz_tustin, "Tustin", T)

  # Compute step responses
  t = 0:T:10
  n_points = length(t)

  y_cont = step(G_s, t)
  y_forward = step(Gz_forward, t)
  y_backward = step(Gz_backward, t)
  y_tustin = step(Gz_tustin, t)

  # Debug: Check dimensions
  println("Debug: y_cont.y size = ", size(y_cont.y))
  println("Debug: Expected length = ", n_points)

  # Extract data (flatten 3D array to vector)
  y_cont_vec = vec(y_cont.y[:, :, 1])  # [n_outputs, n_time, n_inputs] -> vector
  y_forward_vec = vec(y_forward.y[:, :, 1])
  y_backward_vec = vec(y_backward.y[:, :, 1])
  y_tustin_vec = vec(y_tustin.y[:, :, 1])

  # Ensure lengths match
  if length(y_cont_vec) != n_points
    error("Mismatch in step response length for T = $T")
  end

  # Plot step response
  plt = plot(t, y_cont_vec, label="Continuous", title="Step Response (T = $T)", lw=2)
  plot!(t, y_forward_vec, label="Forward Euler", lw=2)
  plot!(t, y_backward_vec, label="Backward Euler", lw=2)
  plot!(t, y_tustin_vec, label="Tustin", lw=2)
  xlabel!("Time (s)")
  ylabel!("Output")

  # Display and save plot
  display(plt)
  savefig(plt, joinpath(plot_dir, "step_response_T_$T.png"))
end

println("\nSummary:")
println("G(s) = 1/(s^2 + 1) is marginally stable (poles at ±i).")
println("Discretization stability varies by method and sampling period.")