# Add packages

using Vann
using DataAssim
using PyPlot
using Distributions
using DataFrames



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

function run_filter(st_snow, st_hydro, prec, tair, epot, q_obs, npart)

    srand(1);

    # Number of elevation bands (rows) and time steps (cols)

    nzones = size(prec, 1);
    ntimes = size(prec, 2);

    # Initilize state variables

    st_snow  = [deepcopy(st_snow) for i in 1:npart];
    st_hydro = [deepcopy(st_hydro) for i in 1:npart];
    
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

# Model choices

snow_choice = TinStandardType;
hydro_choice = HbvType;

# Read data

path_inputs = Pkg.dir("Vann", "data_atnasjo");

date, tair, prec, q_obs, frac = load_data(path_inputs);

# Compute potential evapotranspiration

epot = epot_zero(date);

# Initilize model

st_snow = eval(Expr(:call, snow_choice, frac));
st_hydro = eval(Expr(:call, hydro_choice, frac));

# Run calibration

param_opt = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs);

# Reinitilize model

param_snow  = param_opt[1:length(st_snow.param)]
param_hydro = param_opt[length(st_snow.param)+1:end]

st_snow = eval(Expr(:call, snow_choice, param_snow, frac));
st_hydro = eval(Expr(:call, hydro_choice, param_hydro, frac));

# Run particle filter

npart = 3000;

q_res = run_filter(st_snow, st_hydro, prec, tair, epot, q_obs, npart)

# Plot results

q_mean = q_res[:, 1];
q_min  = q_res[:, 2];
q_max  = q_res[:, 3];

df_res = DataFrame(date = date, q_obs = q_obs, q_mean = q_mean, q_min = q_min, q_max = q_max);

fig = plt[:figure](figsize = (12,7))

plt[:style][:use]("ggplot")

plt[:plot](df_res[:date], df_res[:q_obs], linewidth = 1.2, color = "k", label = "Observed", zorder = 1)
plt[:fill_between](df_res[:date], df_res[:q_max], df_res[:q_min], facecolor = "r", edgecolor = "r", label = "Simulated", alpha = 0.55, zorder = 2)
plt[:legend]()

