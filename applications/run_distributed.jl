using Vann

# Read precipitation data

function read_prec(date)

year  = Dates.format(date, "yyyy");
month = Dates.format(date, "mm");
day   = Dates.format(date, "dd");

#f = open("//hdata/grid/metdata/met_obs_v2.0/rr/$(year)/rr_$(year)_$(month)_$(day).bil","r");
f = open("C:/MetData/rr/$(year)/rr_$(year)_$(month)_$(day).bil","r");

tmp = read(f, UInt16, 1550*1195);

ikeep = tmp .!= 65535;

data = map(x -> convert(Float64, x) * 0.1, tmp[ikeep]);

close(f)

return(data)

end

# Read air temperature data

function read_tair(date)

year  = Dates.format(date, "yyyy");
month = Dates.format(date, "mm");
day   = Dates.format(date, "dd");

#f = open("//hdata/grid/metdata/met_obs_v2.0/tm/$(year)/tm_$(year)_$(month)_$(day).bil","r");
f = open("C:/MetData/tm/$(year)/tm_$(year)_$(month)_$(day).bil","r");

tmp = read(f, UInt16, 1550*1195);

ikeep = tmp .!= 65535;

data = map(x -> convert(Float64, x) * 0.1 - 273.15, tmp[ikeep]);

close(f)

return(data)

end

################################################################################

function run_dist(date_vec)

  # Number of computation elements

  ncells = 521197;

  # Initilize state variables

  tstep = 1

  st_snow  = [TinBasic(tstep, [1.0]) for i in 1:ncells];
  st_hydro = [Gr4j(tstep) for i in 1:ncells];

  # Allocate output arrays

  q_sim = zeros(Float64, ncells);

  for date in date_vec

    println(date)

    # Load input data

    prec = read_prec(date);
    tair = read_tair(date);
    epot = zeros(Float64, ncells);

    for icell = 1:ncells

      # Get input to snow model

      st_snow[icell].prec[1] = prec[icell];
      st_snow[icell].tair[1] = tair[icell];

      # Run snow model

      snow_model(st_snow[icell]);

      # Get input to hydrological routing model

      st_hydro[icell].infilt = st_snow[icell].infilt;
      st_hydro[icell].epot   = epot[icell];

      # Run hydrological routing model

      q_sim[icell] = hydro_model(st_hydro[icell]);

    end

  end

  return(q_sim);

end

################################################################################

# Simulation period

date_vec = Date(2000, 1, 1):Date(2000, 1, 10);

@time run_dist(date_vec);
