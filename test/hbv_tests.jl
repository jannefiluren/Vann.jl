using Vann
using Base.Test

################################################################################

# Test of Gr4j

# Read data

data = readdlm("../data_airgr/test_data.txt", ',', header = true);

prec  = data[1][:,1];
epot  = data[1][:,2];
q_obs = data[1][:,3];

prec = transpose(prec);
epot = transpose(epot);

frac = zeros(Float64, 1);

# Select model

st_hydro = HbvType(frac);

# Run model

q_sim = run_model(st_hydro, prec, epot);

# Compute largest error

q_min = minimum(q_sim);
q_max = maximum(q_sim);

@test q_min >= 0.
@test q_max <= 1000.
