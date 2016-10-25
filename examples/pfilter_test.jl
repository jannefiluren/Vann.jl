# Add packages

using RCall
using Distributions
using DataFrames
using Vann

# Particle filter

function run_filter(prec, tair, q_obs, param_snow, param_hydro, frac, npart)

  srand(1);

  # Number of elevation bands (rows) and time steps (cols)

  nzones = size(prec, 1);
  ntimes = size(prec, 2);

  # Initilize state variables

  st_snow  = [Vann.TinBasicType(param_snow, frac) for i in 1:npart];
  st_hydro = [Vann.Gr4jType(param_hydro, frac) for i in 1:npart];

  for i in eachindex(st_snow)
    st_hydro[i].st = zeros(Float64, 2);
  end

  # Initilize particles

  wk = ones(npart) / npart;

  # Run model

  q_tmp = zeros(Float64, npart);
  q_sim = zeros(Float64, npart, ntimes);

  for itime = 1:ntimes

    for ipart = 1:npart

      perturb_input(st_snow[ipart], prec, tair, itime);

      Vann.snow_model(st_snow[ipart]);

      get_input(st_snow[ipart], st_hydro[ipart]);

      q_sim[ipart, itime] = Vann.hydro_model(st_hydro[ipart]);

    end

    # Run particle filter

    for ipart = 1:npart

      wk[ipart] = pdf( Normal(q_obs[itime], max(0.5*q_obs[itime],0.5) ), q_tmp[ipart] ) * wk[ipart];

    end

    if sum(wk) > 0.0
      wk = wk / sum(wk);
    else
      wk = ones(npart) / npart;
    end

    Neff = 1 / sum(wk.^2);

    if round(Int64, Neff) < round(Int64, npart * 0.5)

      println("Resampled at step: $itime")

      indx = Vann.resample(wk);

      st_snow  = [deepcopy(st_snow[i]) for i in indx];
      st_hydro = [deepcopy(st_hydro[i]) for i in indx];

      wk = ones(npart) / npart;

    end

  end

  return(q_sim);

end

# Read data

date, tair, prec, q_obs, frac = load_data("../data_atnasjo", "Q_ref.txt");

# Parameters

param_snow  = [0.0, 3.69, 1.02];
param_hydro = [74.59, 0.81, 214.98, 1.24];

# Run model

npart = 3000;

q_sim = run_filter(prec, tair, q_obs, param_snow, param_hydro, frac, npart);

# Plot results

if true

  x_data = collect(1:size(q_sim,2));
  q_mean = q_obs; #vec(mean(q_sim,1));
  q_min  = vec(minimum(q_sim,1));
  q_max  = vec(maximum(q_sim,1));

  df_fs = DataFrame(x = x_data, q_mean = q_mean, q_min = q_min, q_max = q_max);

  R"""
  library(labeling, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  library(ggplot2, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  library(yaml, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  library(plotly, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  """

  R"""
  ggplot($df_fs, aes(x)) +
  geom_ribbon(aes(ymin = q_min, ymax = q_max), fill = "blue") +
  geom_line(aes(y = q_mean),linetype="dashed") + theme_bw()
  ggplotly()
  """

end
