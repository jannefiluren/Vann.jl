
# For running the test, execute these two lines:

# cd(string(Pkg.dir("Vann"),"/test"))
# include("hbv_tests.jl")

using Vann

# Some fake data

frac = zeros(Float64, 1)
tstep = 24.0

# Create input for the model using the Hbv (see file hydro_hbv.jl)

st_hbv = Hbv(tstep)

# Run the model for one step and measure time + memory

hydro_model(st_hbv)

@time hydro_model(st_hbv)

@time hydro_model(st_hbv)

@time hydro_model(st_hbv)
