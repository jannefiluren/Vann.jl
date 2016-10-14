
# For running the test, execute these two lines:

# cd(string(Pkg.dir("Vann"),"/test"))
# include("hbv_tests.jl")

using Vann

# Some fake data

frac = zeros(Float64, 1);

# Create input for the model using the HbvType (see file hydro_hbv.jl)

st_hbv = HbvType(frac);

# Run the model for one step and measure time + memory

hydro_model(st_hbv);

@time hydro_model(st_hbv);

@time hydro_model(st_hbv);

@time hydro_model(st_hbv);
