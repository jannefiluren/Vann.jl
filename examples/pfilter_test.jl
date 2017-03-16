# Add packages

using RCall
using Distributions
using DataFrames
using Vann
using DataAssim


# Perturb input data for snow model

function perturb_input(st_snow, prec, tair, itime)

  n = Uniform(0.5, 1.5);
  prec_noise = rand(n, 1);

  n = Normal(0.0, 2);
  tair_noise = rand(n, 1);

  # Assign inputs to snow model

  for izone in eachindex(st_snow.prec)

    st_snow.prec[izone] = prec[izone, itime] * prec_noise[1];
    st_snow.tair[izone] = tair[izone, itime] + tair_noise[1];

  end

end


# Particle filter

function run_filter(prec, tair, epot, q_obs, param_snow, param_hydro, frac, npart)

  srand(1);

  # Number of elevation bands (rows) and time steps (cols)

  nzones = size(prec, 1);
  ntimes = size(prec, 2);

  # Initilize state variables

  st_snow  = [TinBasicType(param_snow, frac) for i in 1:npart];
  st_hydro = [Gr4jType(param_hydro, frac) for i in 1:npart];

  for i in eachindex(st_snow)
    st_hydro[i].st = zeros(Float64, 2);
  end

  # Initilize particles

  wk = ones(npart) / npart;

  # Run model

  q_sim = zeros(Float64, npart);
  q_res = zeros(Float64, ntimes, 3);

  for itime = 1:ntimes

    for ipart = 1:npart

      perturb_input(st_snow[ipart], prec, tair, itime);

      snow_model(st_snow[ipart]);

      get_input(st_snow[ipart], st_hydro[ipart], epot, itime);

      q_sim[ipart] = hydro_model(st_hydro[ipart]);

    end

    # Run particle filter

    if true

      for ipart = 1:npart

        wk[ipart] = pdf(Normal(q_obs[itime], max(0.1 * q_obs[itime], 0.1)), q_sim[ipart]) * wk[ipart];

      end

      if sum(wk) > 0.0
        wk = wk / sum(wk);
      else
        wk = ones(npart) / npart;
      end

      # Perform resampling

      Neff = 1 / sum(wk.^2);

      if round(Int64, Neff) < round(Int64, npart * 0.8)

        println("Resampled at step: $itime")

        indx = resample(wk);

        st_snow  = [deepcopy(st_snow[i]) for i in indx];
        st_hydro = [deepcopy(st_hydro[i]) for i in indx];

        wk = ones(npart) / npart;

      end

    end

    # Store results

    q_res[itime, 1] = sum(wk .* q_sim);
    q_res[itime, 2] = minimum(q_sim);
    q_res[itime, 3] = maximum(q_sim);

  end

  return(q_res);

end


# Read data

date, tair, prec, q_obs, frac = load_data("../data_atnasjo");

# Compute potential evapotranspiration

epot = epot_zero(date);

# Parameters

param_snow  = [-0.350484, 1.0, 0.7082];
param_hydro = [1.0, 4.29214, 125.103, 1.26226];

# Run model

npart = 3000;

q_res = run_filter(prec, tair, epot, q_obs, param_snow, param_hydro, frac, npart);

# Plot results

if true

  x_data = collect(1:size(q_res,1));
  q_mean = q_res[:, 1];
  q_min  = q_res[:, 2];
  q_max  = q_res[:, 3];

  df_res = DataFrame(date = Dates.format(date, "yyyy-mm-dd"), q_obs = q_obs, q_mean = q_mean, q_min = q_min, q_max = q_max);

  R"""
  library(labeling, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  library(ggplot2, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  library(yaml, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")
  library(plotly, lib.loc="C:/Users/jmg/Documents/R/win-library/3.2")

  df <- $df_res
  df$date <- as.Date(df$date)

  ggplot(df, aes(date)) +
  geom_ribbon(aes(ymin = q_min, ymax = q_max), fill = "blue") +
  geom_line(aes(y = q_obs), colour = "black", size = 1) +
  geom_line(aes(y = q_mean), colour = "red", size = 0.5) +
  theme_bw()
  ggplotly()
  """

end
