using Vann
using Base.Test


################################################################################

# Test of Gr4j

# Read data

filename = joinpath(dirname(@__FILE__), "../data/airgr/test_data.txt")

data = readdlm(filename, ',', header = true)

prec  = data[1][:,1]
epot  = data[1][:,2]
q_obs = data[1][:,3]

prec = transpose(prec)
epot = transpose(epot)

frac = zeros(Float64, 1)

param  = [257.238, 1.012, 88.235, 2.208]

tstep = 1.0

# Select model

st_gr4j = Gr4j(tstep, param);

# Run model

q_sim = run_model(st_gr4j, prec, epot);

# Compute largest error

err_max = maximum(map(abs, q_sim - q_obs));

@test err_max < 1.

println("Gr4j maximum error = " * string(err_max))


################################################################################

# Test of TinBasic and Gr4j

# Load data

filename = joinpath(dirname(@__FILE__), "../data/atnasjo")

date, tair, prec, q_obs, frac = load_data(filename, "Q_ref.txt")

tstep = 1.0

# Compute potential evapotranspiration

epot = epot_zero(date)

# Parameters

param_snow  = [0.0, 3.69, 1.02]
param_hydro = [74.59, 0.81, 214.98, 1.24]

# Select model

st_snow  = TinBasic(tstep, param_snow, frac)
st_hydro = Gr4j(tstep, param_hydro)

q_sim = run_model(st_snow, st_hydro, date, tair, prec, epot)

# Compute largest error

err_max = maximum(map(abs, q_sim - q_obs))

println("Gr4j + TinBasic maximum error = " * string(err_max))


################################################################################

# Test of TinStandard and Gr4j

# Load data

filename = joinpath(dirname(@__FILE__), "../data/atnasjo")

date, tair, prec, q_obs, frac = load_data(filename, "Q_ref.txt")

tstep = 1.0

# Compute potential evapotranspiration

epot = epot_zero(date)

# Parameters

param_snow  = [0.0, 3.69, 3.69, 0., 1.02]
param_hydro = [74.59, 0.81, 214.98, 1.24]

# Select model

st_snow  = TinStandard(tstep, param_snow, frac)
st_hydro = Gr4j(tstep, param_hydro)

q_sim = run_model(st_snow, st_hydro, date, tair, prec, epot)

# Compute largest error

err_max = maximum(map(abs, q_sim - q_obs))

println("Gr4j + TinBasic maximum error = " * string(err_max))
