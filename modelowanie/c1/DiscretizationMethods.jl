module DiscretizationMethods

using ControlSystems
using LinearAlgebra

export forward_euler, backward_euler, tustin_method, impulse_invariant, zero_order_hold, first_order_hold, pole_zero_matching

# 1. Forward Difference (Forward Euler)
"""
    forward_euler(G::TransferFunction, T::Float64)
Discretize a continuous system using Forward Euler method: s = (z - 1) / T.
Supports higher-order systems via state-space discretization.
"""
function forward_euler(G::TransferFunction, T::Float64)
  sys_ss = ss(G)
  A, B, C, D = sys_ss.A, sys_ss.B, sys_ss.C, sys_ss.D
  Ad = I + T * A  # x[k+1] = x[k] + T * A * x[k]
  Bd = T * B
  return tf(ss(Ad, Bd, C, D, T))
end

# 2. Backward Difference (Backward Euler)
"""
    backward_euler(G::TransferFunction, T::Float64)
Discretize a continuous system using Backward Euler method: s = (z - 1) / (T * z).
Supports higher-order systems via state-space discretization.
"""
function backward_euler(G::TransferFunction, T::Float64)
  sys_ss = ss(G)
  A, B, C, D = sys_ss.A, sys_ss.B, sys_ss.C, sys_ss.D
  Ad = inv(I - T * A)  # (I - T * A) * x[k+1] = x[k]
  Bd = T * Ad * B
  return tf(ss(Ad, Bd, C, D, T))
end

# 3. Tustin’s Method (Trapezoidal)
"""
    tustin_method(G::TransferFunction, T::Float64)
Discretize a continuous system using Tustin’s (Trapezoidal) method via ControlSystems.jl.
"""
function tustin_method(G::TransferFunction, T::Float64)
  return c2d(G, T, :tustin)
end

# 4. Impulse Invariant
"""
    impulse_invariant(G::TransferFunction, T::Float64)
Discretize a continuous system using Impulse Invariant method, matching impulse response.
Limited to first-order systems in this implementation.
"""
function impulse_invariant(G::TransferFunction, T::Float64)
  sys_ss = ss(G)
  A, B, C, D = sys_ss.A, sys_ss.B, sys_ss.C, sys_ss.D
  Ad = exp(A * T)  # Discrete-time state matrix
  Bd = A \ (Ad - I) * B  # Assuming A invertible
  return tf(ss(Ad, Bd, C, D, T))
end

# 5. Zero-Order Hold (ZOH)
"""
    zero_order_hold(G::TransferFunction, T::Float64)
Discretize a continuous system using Zero-Order Hold (ZOH) via ControlSystems.jl.
"""
function zero_order_hold(G::TransferFunction, T::Float64)
  return c2d(G, T, :zoh)
end

# 6. First-Order Hold (FOH)
"""
    first_order_hold(G::TransferFunction, T::Float64)
Discretize a continuous system using First-Order Hold (FOH) with linear interpolation.
Limited to first-order systems in this implementation.
"""
function first_order_hold(G::TransferFunction, T::Float64)
  sys_ss = ss(G)
  A, B, C, D = sys_ss.A, sys_ss.B, sys_ss.C, sys_ss.D
  Ad = exp(A * T)
  Bd = (A \ (Ad - I) * B + (A^2 \ (Ad - I - A * T)) * B / T)  # FOH approximation
  return tf(ss(Ad, Bd, C, D, T))
end

# 7. Pole-Zero Matching
"""
    pole_zero_matching(G::TransferFunction, T::Float64)
Discretize a continuous system using Pole-Zero Matching via ControlSystems.jl.
"""
function pole_zero_matching(G::TransferFunction, T::Float64)
  return c2d(G, T, :matched)
end

end # module