include("DiscretizationMethods.jl")
using .DiscretizationMethods
using ControlSystems
using Plots
using LinearAlgebra

# Create plots directory if it doesn’t exist
plot_dir = joinpath(pwd(), "plots/c1.2")
mkpath(plot_dir)

# Define the continuous system G(s) = 1 / (s^2 + s + 1)
G_s = tf([1], [1, 1, 1])

# Sampling periods to test
T_values = [0.5, 0.1, 0.01]  # fs = 2 Hz, 10 Hz, 100 Hz

# Function to analyze poles and stability
function analyze_discretization(Gz, method_name, T)
  poles_z = pole(Gz)
  mag_poles = abs.(poles_z)
  stable = all(mag_poles .< 1.0 - 1e-6)
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

  # Discretize using each method
  Gz_forward = forward_euler(G_s, T)
  Gz_backward = backward_euler(G_s, T)
  Gz_tustin = tustin_method(G_s, T)

  # Analyze stability
  forward_poles = analyze_discretization(Gz_forward, "Forward Euler", T)
  backward_poles = analyze_discretization(Gz_backward, "Backward Euler", T)
  tustin_poles = analyze_discretization(Gz_tustin, "Tustin", T)

  # Step responses
  t = 0:T:10
  y_cont = step(G_s, t)
  y_forward = step(Gz_forward, t)
  y_backward = step(Gz_backward, t)
  y_tustin = step(Gz_tustin, t)

  y_cont_vec = vec(y_cont.y[:, :, 1])
  y_forward_vec = vec(y_forward.y[:, :, 1])
  y_backward_vec = vec(y_backward.y[:, :, 1])
  y_tustin_vec = vec(y_tustin.y[:, :, 1])

  # Step response plot
  plt_step = plot(t, y_cont_vec, label="Continuous", title="Step Response (T = $T)", lw=2)
  plot!(t, y_forward_vec, label="Forward Euler", lw=2)
  plot!(t, y_backward_vec, label="Backward Euler", lw=2)
  plot!(t, y_tustin_vec, label="Tustin", lw=2)
  xlabel!("Time (s)")
  ylabel!("Output")
  display(plt_step)
  savefig(plt_step, joinpath(plot_dir, "c1_2_step_response_T_$T.png"))

  # Frequency responses (Bode plot)
  w = range(0.01, stop=10, length=100)
  mag_cont, phase_cont = bode(G_s, w)
  mag_forward, phase_forward = bode(Gz_forward, w)
  mag_backward, phase_backward = bode(Gz_backward, w)
  mag_tustin, phase_tustin = bode(Gz_tustin, w)

  println("Debug: mag_cont size = ", size(mag_cont))
  println("Debug: mag_tustin size = ", size(mag_tustin))
  println("Debug: w length = ", length(w))

  mag_cont_vec = vec(mag_cont[1, 1, :])
  mag_forward_vec = vec(mag_forward[1, 1, :])
  mag_backward_vec = vec(mag_backward[1, 1, :])
  mag_tustin_vec = vec(mag_tustin[1, 1, :])

  mag_cont_vec = max.(mag_cont_vec, 1e-6)
  mag_forward_vec = max.(mag_forward_vec, 1e-6)
  mag_backward_vec = max.(mag_backward_vec, 1e-6)
  mag_tustin_vec = max.(mag_tustin_vec, 1e-6)

  if length(mag_cont_vec) != length(w)
    error("Mismatch in Bode magnitude length for T = $T: got $(length(mag_cont_vec)), expected $(length(w))")
  end

  plt_bode = plot(w, 20 * log10.(mag_cont_vec), label="Continuous",
    title="Bode Magnitude (T = $T)", lw=2, xaxis=:log10, yaxis=:log)
  plot!(w, 20 * log10.(mag_forward_vec), label="Forward Euler", lw=2)
  plot!(w, 20 * log10.(mag_backward_vec), label="Backward Euler", lw=2)
  plot!(w, 20 * log10.(mag_tustin_vec), label="Tustin", lw=2)
  xlabel!("Frequency (rad/s)")
  ylabel!("Magnitude (dB)")
  display(plt_bode)
  savefig(plt_bode, joinpath(plot_dir, "c1_2_bode_magnitude_T_$T.png"))
end

# Manual computation for Tustin method (T = 0.1) - 5 steps
println("\nManual Computation for Tustin Method (T = 0.1):")
T = 0.1

# Recompute Gz_tustin explicitly
Gz_tustin = c2d(G_s, T, :tustin)

# Debugging
println("Debug: Gz_tustin = ", Gz_tustin)
println("Debug: Type of Gz_tustin = ", typeof(Gz_tustin))
if Gz_tustin === nothing || !isa(Gz_tustin, TransferFunction)
  error("Tustin discretization failed: Gz_tustin = $Gz_tustin")
end

# Extract numerator and denominator coefficients using numvec and denvec
b = numvec(Gz_tustin)[1]  # numvec returns a vector of vectors; [1] for SISO
a = denvec(Gz_tustin)[1]
println("Debug: Numerator coefficients (b) = ", b)
println("Debug: Denominator coefficients (a) = ", a)

println("G(z) = ", Gz_tustin)
println("Difference equation coefficients:")
println("  Numerator (b): ", round.(b, digits=4))
println("  Denominator (a): ", round.(a, digits=4))

# Difference equation: a0*y[k] + a1*y[k-1] + a2*y[k-2] = b0*u[k] + b1*u[k-1] + b2*u[k-2]
# Normalized: y[k] = (-a1*y[k-1] - a2*y[k-2] + b0*u[k] + b1*u[k-1] + b2*u[k-2]) / a0
a0, a1, a2 = a[1], a[2], a[3]
b0, b1, b2 = b[1], b[2], b[3]

# Step input: u[k] = 1 for k >= 0
u = ones(7)  # Enough for 5 steps plus initial conditions
y = zeros(7)  # y[1] = y[0], y[2] = y[1], etc., initial conditions y[-1] = y[-2] = 0

# Compute first 5 steps (k = 0 to 4)
for k = 3:7
  y[k] = (-a1 * y[k-1] - a2 * y[k-2] + b0 * u[k] + b1 * u[k-1] + b2 * u[k-2]) / a0
end

# Print manual results
println("\nManual step response (T = 0.1):")
for k = 2:6  # t = 0, 0.1, 0.2, 0.3, 0.4
  t_step = (k - 2) * T
  println("t = $t_step, y[$(k-2)] = ", round(y[k], digits=4))
end

# Compare with simulation
t_sim = 0:T:0.4
y_sim = step(Gz_tustin, t_sim)
y_sim_vec = vec(y_sim.y[:, :, 1])
println("\nSimulated step response (T = 0.1):")
for (i, t_val) in enumerate(t_sim)
  println("t = $t_val, y = ", round(y_sim_vec[i], digits=4))
end