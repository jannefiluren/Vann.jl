"""
    perturb_input(st_snow, prec, tair, itime)

Perturb input data for snow model
"""
function perturb_input(st_snow, prec, tair, itime)

    n = Uniform(0.5, 1.5)
    prec_noise = rand(n, 1)

    n = Normal(0.0, 2)
    tair_noise = rand(n, 1)

    # Assign inputs to snow model

    for izone in eachindex(st_snow.prec)

        st_snow.prec[izone] = prec[izone, itime] * prec_noise[1]
        st_snow.tair[izone] = tair[izone, itime] + tair_noise[1]

    end

end


"""
    particle_filter(st_snow, st_hydro, prec, tair, epot, q_obs, npart)

Run the particle filter for any combination of snow and hydrological routing model.
"""
function particle_filter(st_snow, st_hydro, prec, tair, epot, q_obs, npart)

    srand(1)

    # Number of elevation bands (rows) and time steps (cols)

    nzones = size(prec, 1)
    ntimes = size(prec, 2)

    # Initilize state variables

    st_snow  = [deepcopy(st_snow) for i in 1:npart]
    st_hydro = [deepcopy(st_hydro) for i in 1:npart]

    # Initilize particles

    wk = ones(npart) / npart

    # Run model

    q_sim = zeros(Float64, npart)
    q_res = zeros(Float64, ntimes, 3)

    for itime = 1:ntimes

        for ipart = 1:npart

            perturb_input(st_snow[ipart], prec, tair, itime)

            snow_model(st_snow[ipart])

            get_input(st_snow[ipart], st_hydro[ipart], epot, itime)

            q_sim[ipart] = hydro_model(st_hydro[ipart])

        end

        # Run particle filter

        if true

            for ipart = 1:npart

                wk[ipart] = pdf(Normal(q_obs[itime], max(0.1 * q_obs[itime], 0.1)), q_sim[ipart]) * wk[ipart]

            end

            if sum(wk) > 0.0
                wk = wk / sum(wk)
            else
                wk = ones(npart) / npart
            end

            # Perform resampling

            Neff = 1 / sum(wk.^2)

            if round(Int64, Neff) < round(Int64, npart * 0.8)

                println("Resampled at step: $itime")

                indx = resample(wk)

                st_snow  = [deepcopy(st_snow[i]) for i in indx]
                st_hydro = [deepcopy(st_hydro[i]) for i in indx]

                wk = ones(npart) / npart

            end

        end

        # Store results

        q_res[itime, 1] = sum(wk .* q_sim)
        q_res[itime, 2] = minimum(q_sim)
        q_res[itime, 3] = maximum(q_sim)

    end

    return(q_res)

end


"""
    enkf_filter(st_snow, st_hydro, prec, tair, epot, q_obs, nens)

Run the ensemble Kalman filter for any combination of snow and hydrological
routing model.
"""
function enkf_filter(st_snow, st_hydro, prec, tair, epot, q_obs, nens)

  srand(1)

  # Number of elevation bands (rows) and time steps (cols)

  nzones = size(prec, 1)
  ntimes = size(prec, 2)

  # Initilize state variables

  st_snow  = [deepcopy(st_snow) for i in 1:nens]
  st_hydro = [deepcopy(st_hydro) for i in 1:nens]

  # Allocate arrays

  q_res  = zeros(Float64, ntimes, 3)
  q_sim  = zeros(Float64, 1, nens)

  # Start time Loop

  for itime = 1:ntimes

    # Perturb inputs and run models

    for iens = 1:nens

      perturb_input(st_snow[iens], prec, tair, itime)

      snow_model(st_snow[iens])

      get_input(st_snow[iens], st_hydro[iens], epot, itime)

      q_sim[iens] = hydro_model(st_hydro[iens])

    end

    # Run filter part

    if q_obs[itime] >= 0

      # Perturb observations

      sigma = max(0.1 * q_obs[itime], 0.1)

      obs_ens = q_obs[itime] + sigma * randn(Float64, 1, nens)

      # Update states of hydrological model

      enkf_hydro(st_hydro, obs_ens, q_sim)

      # Update states of snow model

      enkf_snow(st_snow, obs_ens, q_sim)

      # Update simulated discharge

      q_sim  = enkf(q_sim, obs_ens, q_sim)

      q_sim[q_sim .< 0] = 0.

    end

    # Store results

    q_res[itime, 1] = mean(q_sim)
    q_res[itime, 2] = minimum(q_sim)
    q_res[itime, 3] = maximum(q_sim)

  end

  return(q_res)

end
