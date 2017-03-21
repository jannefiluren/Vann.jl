
import Vann
using PyPlot

# Load data

date, tair, prec, q_obs, frac = Vann.load_data("data_atnasjo");

# Parameters

param_snow  = [0.0, 3.69, 1.02];
param_hydro = [100., 0.8, 0.15, 0.05, 0.01, 1., 2., 30., 2.5];

# Select model

st_snow  = Vann.TinBasic(param_snow, frac);
st_hydro = Vann.Hbv(param_hydro, frac);

q_sim = Vann.run_model(st_snow, st_hydro, date, tair, prec);

plot(1:length(q_sim), q_sim, linewidth=2.0, 1:length(q_obs), q_obs, linewidth=1.0);
title("Simulated (blue) and observed (green) runoff");
