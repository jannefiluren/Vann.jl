using Vann

# Test of Hbv

# Read data

data = readdlm("../data_airgr/test_data.txt", ',', header = true);

prec  = data[1][:,1];
epot  = data[1][:,2];
q_obs = data[1][:,3];

prec = transpose(prec);
epot = transpose(epot);

frac = zeros(Float64, 1);

param = [100., 0.8, 0.05, 0.05, 0.01, 1., 2., 30., 2.5];

# Select model

st_hbv = HbvType(param, frac);

# Run model

q_sim = run_model(st_hbv, prec, epot);
