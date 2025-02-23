Metody oparte na aproksymacji pochodnej

- Różnica wprzód (forward)
- Różnica wstecz
- Tustina (metoda trapezów)

Metody oparte na odpowiedniku dykretnej transmitancji ciągłej

- Odpowiednik impulsow
- Odpowiednik skokowy (ZOH)
- Odpowiednik z odpowiedzi liniowo-narastającej (FOH)
- odpowiednika biegunowo-zerowego

Below is a table summarizing the discretization methods you listed—those based on derivative approximation and those based on matching the response of a continuous transfer function—along with their availability in the Julia ecosystem, specifically focusing on packages or functions that provide solutions. I’ve included both direct support in `ControlSystems.jl` and potential external packages that could facilitate implementation where native support is lacking. The table is designed to be clear and actionable.

---

### Table: Discretization Methods and Julia Support

| **Method** | **English Name** | **Availability in Julia** | **Package/Function** | **Notes** |
| --- | --- | --- | --- | --- |
| **Metody oparte na aproksymacji pochodnej** | **Derivative Approximation Methods** |  |  |  |
| Różnica wprzód | Forward Difference (Forward Euler) | Not directly supported, but possible manually | `Symbolics.jl`, `ModelingToolkit.jl` | Use \( s = \frac{z - 1}{T} \) substitution; simple to implement manually |
| Różnica wstecz | Backward Difference (Backward Euler) | Not directly supported, but possible manually | `Symbolics.jl`, `ModelingToolkit.jl` | Use \( s = \frac{z - 1}{T z} \) substitution; manually derive \( G(z) \) |
| Tustina (metoda trapezów) | Tustin’s Method (Trapezoidal) | Directly supported | `ControlSystems.jl` (`c2d(sys, T, :tustin)`) | Standard option; uses \( s = \frac{2}{T} \frac{z - 1}{z + 1} \) |
| **Metody oparte na odpowiedniku dyskretnej transmitancji ciągłej** | **Response Matching Methods** |  |  |  |
| Odpowiednik impulsowy | Impulse Invariant | Not directly supported, but possible with external tools | `DSP.jl` (`impinvar`) | Tailored to filters; requires adaptation for `ControlSystems.jl` compatibility |
| Odpowiednik skokowy (ZOH) | Zero-Order Hold (ZOH) | Directly supported (default) | `ControlSystems.jl` (`c2d(sys, T)` or `:zoh`) | Most common method; assumes input held constant between samples |
| Odpowiednik z odpowiedzi liniowo-narastającej | First-Order Hold (FOH) | Not directly supported, but possible manually | `DifferentialEquations.jl`, `ModelingToolkit.jl` | Requires interpolation and fitting; no pre-built solution in `ControlSystems.jl` |
| Odpowiednik biegunowo-zerowy | Pole-Zero Matching | Directly supported | `ControlSystems.jl` (`c2d(sys, T, :matched)`) | Maps \( z = e^{sT} \) with gain adjustment; standard option |
