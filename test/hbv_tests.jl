
# cd(string(Pkg.dir("Vann"),"/test"))
# include("hbv_tests.jl")


using Vann

# Read data

prec  = 10.;
epot  = 2.;

frac = zeros(Float64, 1);

# Select model

st_hbv = HbvType(frac);

hydro_model(st_hbv);

@time hydro_model(st_hbv);

@time hydro_model(st_hbv);

@time hydro_model(st_hbv);
