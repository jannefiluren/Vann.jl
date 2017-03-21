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

tstep = 1.0

# Select model

st_hbv = Hbv(tstep, param);

# Run model

q_sim = run_model(st_hbv, prec, epot);



################################################################################

# Test of TinBasic and Gr4j

# Load data

date, tair, prec, q_obs, frac = load_data("../data_atnasjo", "Q_ref.txt");

# Compute potential evapotranspiration

epot = epot_zero(date);

# Parameters

param_snow  = [0.0, 3.69, 1.02];
param_hydro = [100., 0.8, 0.05, 0.05, 0.01, 1., 2., 30., 2.5];

# Select model

tstep = 1.0

st_snow  = TinBasic(tstep, param_snow, frac);
st_hydro = Hbv(tstep, param_hydro);

q_sim = run_model(st_snow, st_hydro, date, tair, prec, epot);
