# Model wrapper for Gr4j

function run_model(st_hydro, prec, epot)

  # Number of time steps

  ntimes = size(prec, 2);

  # Run model

  q_sim = zeros(Float64, ntimes);

  for itime in 1:ntimes

    get_input(st_hydro, prec, epot, itime);

    q_sim[itime] = hydro_model(st_hydro);

  end

  return(q_sim);

end


# Model wrapper for snow model and Gr4j

function run_model(st_snow, st_hydro, date, tair, prec)

  # Number of time steps

  ntimes = size(prec, 2);

  # Run model

  q_sim = zeros(Float64, ntimes);

  for itime in 1:ntimes

    get_input(st_snow, prec, tair, date, itime);

    snow_model(st_snow);

    get_input(st_snow, st_hydro);

    q_sim[itime] = hydro_model(st_hydro);

  end

  return(q_sim)

end
