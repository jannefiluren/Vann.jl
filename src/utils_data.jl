# Load data from text files

function load_data(folder, file_q_obs = "Q_obs.txt", file_tair = "Tair.txt",
                   file_prec = "Prec.txt", file_frac = "Frac.txt")

  # Read runoff data

  tmp   = readdlm("$folder/$file_q_obs", '\t');
  q_obs = convert(Array{Float64,1}, tmp[1:end-100,2]);

  # Read air temperature data

  tmp   = readdlm("$folder/$file_tair", '\t');
  tair  = convert(Array{Float64,2}, tmp[1:end-100,2:end]);
  tair  = transpose(tair);

  # Read precipitation data

  tmp   = readdlm("$folder/$file_prec", '\t');
  prec  = convert(Array{Float64,2}, tmp[1:end-100,2:end]);
  prec  = transpose(prec);

  # Read elevation band data

  frac = readdlm("$folder/$file_frac");
  frac = squeeze(frac,2);

  # Get time data

  date = [Date(tmp[i,1],"yyyy-mm-dd") for i in 1:size(tmp,1)-100];

  # Return data

  return date, tair, prec, q_obs, frac

end

# Assign input data to snow model

function get_input(st_snow::TinStandardType, prec, tair, date, itime)

  # Assign inputs to snow model

  st_snow.date = date[itime];

  for izone in eachindex(st_snow.prec)

    st_snow.prec[izone] = prec[izone, itime];
    st_snow.tair[izone] = tair[izone, itime];

  end

end

function get_input(st_snow::TinBasicType, prec, tair, date, itime)

  # Assign inputs to snow model

  for izone in eachindex(st_snow.prec)

    st_snow.prec[izone] = prec[izone, itime];
    st_snow.tair[izone] = tair[izone, itime];

  end

end

# Assign input data to hydrological model

function get_input(st_hydro::Gr4jType, prec, epot, itime)

  st_hydro.infilt = prec[itime];
  st_hydro.epot   = epot[itime];

end

function get_input(st_snow::SnowType, st_hydro::HydroType)

  st_hydro.infilt = st_snow.infilt;

end
