
# cd(string(Pkg.dir("Vann"),"/test"))
# include("gr4j_tests_2.jl")


using Distributions

include("../src/hydro_gr4j.jl")

# Read data

prec  = 10.;
epot  = 2.;

frac = zeros(Float64, 1);

# Select model

st_gr4j = Gr4jType(frac);

hydro_model(st_gr4j);

@time hydro_model(st_gr4j);

@time hydro_model(st_gr4j);

@time hydro_model(st_gr4j);
