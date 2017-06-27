# Load data from text files

function load_data(folder, file_q_obs = "Q_obs.txt", file_tair = "Tair.txt",
                   file_prec = "Prec.txt", file_frac = "Frac.txt")

  # Read air temperature data

  str   = readline("$folder/$file_tair")
  nsep  = length(matchall(r";", str))
  tmp   = CSV.read("$folder/$file_tair", delim = ";", header = false,
                   dateformat="yyyy-mm-dd HH:MM", nullable = false, types = vcat(DateTime, repmat([Float64], nsep)))
  tair  = Array(tmp[:, 2:end])
  tair  = transpose(tair)

  # Read precipitation data

  str   = readline("$folder/$file_tair")
  nsep  = length(matchall(r";", str))
  tmp   = CSV.read("$folder/$file_prec", delim = ";", header = false,
                  dateformat="yyyy-mm-dd HH:MM", nullable = false, types = vcat(DateTime, repmat([Float64], nsep)))
  prec  = Array(tmp[:, 2:end])
  prec  = transpose(prec)

  # Read runoff data

  tmp   = CSV.read("$folder/$file_q_obs", delim = ";", header = false,
                   dateformat="yyyy-mm-dd HH:MM", nullable = false, types = [DateTime, Float64])
  q_obs = Array(tmp[:, 2])

  q_obs[q_obs .== -999.0] = NaN

  # Read elevation band data

  frac = readdlm("$folder/$file_frac")
  frac = squeeze(frac,2)

  # Get time data

  date = Array(tmp[:, 1])

  # Return data

  return date, tair, prec, q_obs, frac

end










# Load operational data from text files

function load_operational(folder, file_q_obs = "Q_obs.txt", file_tair = "Tair.txt",
                   file_prec = "Prec.txt", file_metadata = "metadata.txt")

  # Read air temperature data

  str   = readline("$folder/$file_tair")
  nsep  = length(matchall(r";", str))
  tmp   = CSV.read("$folder/$file_tair", delim = ";", header = false,
                   dateformat="yyyy-mm-dd HH:MM", nullable = false, types = vcat(DateTime, repmat([Float64], nsep)))
  tair  = Array(tmp[:, 2:end])
  tair  = transpose(tair)

  # Read precipitation data

  str   = readline("$folder/$file_tair")
  nsep  = length(matchall(r";", str))
  tmp   = CSV.read("$folder/$file_prec", delim = ";", header = false,
                  dateformat="yyyy-mm-dd HH:MM", nullable = false, types = vcat(DateTime, repmat([Float64], nsep)))
  prec  = Array(tmp[:, 2:end])
  prec  = transpose(prec)

  # Read runoff data

  tmp   = CSV.read("$folder/$file_q_obs", delim = ";", header = false,
                   dateformat="yyyy-mm-dd HH:MM", nullable = false, types = [DateTime, Float64])
  q_obs = Array(tmp[:, 2])

  q_obs[q_obs .== -999.0] = NaN

  # Read elevation band data

  metadata = readtable("$folder/$file_metadata", separator = ';')
  frac = convert(Array{Float64,1}, metadata[:area] / sum(metadata[:area]))

  # Get time data

  date = Array(tmp[:, 1])

  # Return data

  return date, tair, prec, q_obs, frac

end














# Crop data from start to stop date

function crop_data(date, tair, prec, q_obs, date_start, date_stop)

  # Find indicies

  istart = find(date .== date_start)
  istop = find(date .== date_stop)

  # Test if ranges are valid

  if isempty(istart) | isempty(istop)
    error("Cropping data outside range")
  end

  # Crop data

  date  = date[istart[1]:istop[1]]
  tair  = tair[:, istart[1]:istop[1]]
  prec  = prec[:, istart[1]:istop[1]]
  q_obs = q_obs[istart[1]:istop[1]]

  return date, tair, prec, q_obs

end

# Crop data before start date

function crop_data(date, tair, prec, q_obs, date_start)

  # Find indicies

  istart = find(date .== date_start)

  # Test if ranges are valid

  if isempty(istart)
    error("Cropping data outside range")
  end

  # Crop data

  date  = date[istart[1]:end]
  tair  = tair[:, istart[1]:end]
  prec  = prec[:, istart[1]:end]
  q_obs = q_obs[istart[1]:end]

  return date, tair, prec, q_obs

end

# Assign input data to snow model

function get_input(st_snow::Snow, prec, tair, itime)

  for izone in eachindex(st_snow.prec)

    st_snow.prec[izone] = prec[izone, itime]
    st_snow.tair[izone] = tair[izone, itime]

  end

end

# Assign input data to hydrological response model

function get_input(st_hydro::Hydro, prec, epot, itime)

  st_hydro.prec = prec[itime]
  st_hydro.epot = epot[itime]

end

function get_input(st_snow::Snow, st_hydro::Hydro, epot, itime)

  st_hydro.prec = sum(st_snow.frac .* st_snow.q_sim)
  st_hydro.epot = epot[itime]

end
