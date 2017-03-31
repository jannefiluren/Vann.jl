

using Vann
using NetCDF
using ProgressMeter

# Read forcing data

function read_input(date, variable)

  year  = Dates.format(date, "yyyy")
  month = Dates.format(date, "mm")
  day   = Dates.format(date, "dd")

  filename = Pkg.dir("Vann", "data/senorge/$(variable)_$(year)_$(month)_$(day).nc")

  if variable == "rr"
    data = ncread(filename, "precipitation_amount")
  end

  if variable == "tm"
    data = ncread(filename, "mean_temperature")
  end

  data = squeeze(data, 3)

  data = map(x -> convert(Float64, x), data)

  data = round(data, 2)

  data = data[data .!= -999.99]

  return data

end


################################################################################

function run_dist(date_vec)

  # Number of computation elements

  ncells = 606579

  # Initilize state variables

  tstep = 1

  st_snow  = [TinBasic(tstep, [1.0]) for i in 1:ncells]
  st_hydro = [Gr4j(tstep) for i in 1:ncells]

  # Allocate output arrays

  q_sim = zeros(Float64, ncells)

  @showprogress 1 "Computing..." for date in date_vec

    # println(date)

    # Load input data

    prec = read_input(date, "rr")
    tair = read_input(date, "tm")
    epot = zeros(Float64, ncells)

    for icell = 1:ncells

      # Get input to snow model

      st_snow[icell].prec[1] = prec[icell]
      st_snow[icell].tair[1] = tair[icell]

      # Run snow model

      snow_model(st_snow[icell])

      # Get input to hydrological routing model

      st_hydro[icell].infilt = st_snow[icell].infilt
      st_hydro[icell].epot   = epot[icell]

      # Run hydrological routing model

      q_sim[icell] = hydro_model(st_hydro[icell])

    end

  end

  return(q_sim)

end

################################################################################

# Simulation period

date_vec = Date(2010, 1, 1):Date(2010, 1, 10)

run_dist(date_vec)
