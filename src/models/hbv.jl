

"""
The Hbv type contains the state variables (sm, suz, slz, st_uh), the inputs
(epot, prec) for one time step, the parameters (param) and the time step
length (tstep) for the HBV model.
"""
type Hbv <: Hydro

  sm::Float64
  suz::Float64
  slz::Float64
  st_uh::Array{Float64,1}
  hbv_ord::Array{Float64,1}
  epot::Float64
  prec::Float64
  q_sim::Float64
  param::Array{Float64,1}
  tstep::Float64
  time::DateTime

end


"""
    Hbv(tstep, time)

Constructor for HBV with predefined state variables, parameters and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24.
"""
function Hbv(tstep::Float64, time::DateTime)

  sm      = 0.0
  suz     = 0.0
  slz     = 0.0
  st_uh   = zeros(Float64, 20)

  epot   = 0.0
  prec   = 0.0

  q_sim = 0.0

  # fc, lp, k0, k1, k2, beta, perc, ulz, maxbas

  param = [100., 0.8, 0.05, 0.05, 0.01, 1., 2., 30., 2.5]

  hbv_ord = compute_hbv_ord(param[9])

  Hbv(sm, suz, slz, st_uh, hbv_ord, epot, prec, q_sim, param, tstep, time)

end


"""
    Hbv(tstep, time, param)

Constructor for HBV with predefined state variables and inputs. The parameter
values are given as input. The time step (tstep) is given as a fraction of one
day. Thus, for hourly input data tstep should be set to 1/24.
"""
function Hbv(tstep::Float64, time::DateTime, param::Array{Float64,1})

  sm      = 0.0
  suz     = 0.0
  slz     = 0.0
  st_uh   = zeros(Float64, 20)

  epot   = 0.0
  prec   = 0.0

  q_sim = 0.0

  hbv_ord = compute_hbv_ord(param[9])

  Hbv(sm, suz, slz, st_uh, hbv_ord, epot, prec, q_sim, param, tstep, time)

end


"""
    init_states(mdata::Hbv)

Initilize the state variables of the model.
"""
function init_states(mdata::Hbv)

  mdata.sm      = 0.0
  mdata.suz     = 0.0
  mdata.slz     = 0.0

  for i in eachindex(mdata.st_uh)
    mdata.st_uh[i] = 0.0
  end

end


"""
    get_param_range(mdata::Hbv)

Get allowed parameter ranges for the calibration of the model.
"""
function get_param_range(mdata::Hbv)

  param_range_hydro = [(1., 1000.),      # fc
                       (0.5, 0.99),      # lp
                       (0.001, 0.999),   # k0
                       (0.001, 0.999),   # k1
                       (0.001, 0.999),   # k2
                       (1., 5.),         # beta
                       (0.1, 1000.),     # perc
                       (1., 1000.),      # ulz
                       (1., 20.)]       # maxbas

end


"""
    get_states(mdata::Hbv)

Get state variables for computing penelty during calibration.

"""
function get_states(mdata::Hbv)

  return [mdata.suz; mdata.slz]

end


"""
    assign_param(mdata::Hbv, param::Array{Float64,1})

Assign parameter values to the Hbv type.
"""
function assign_param(mdata::Hbv, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

  mdata.hbv_ord = compute_hbv_ord(param[9])

end





"""
    enkf_hydro(mdata::Array{Hbv,1}, obs_ens, q_sim)

Implementation of the ensemble Kalman filter for the HBV model.
"""
function enkf_hydro(mdata::Array{Hbv,1}, obs_ens, q_sim)

  nens = length(mdata)

  # Allocate arrays

  sm    = zeros(Float64, length(mdata[1].sm), nens)
  suz   = zeros(Float64, length(mdata[1].suz), nens)
  slz   = zeros(Float64, length(mdata[1].slz), nens)
  st_uh = zeros(Float64, length(mdata[1].st_uh), nens)

  # Add states to arrays

  for iens = 1:nens

    sm[:, iens]    = mdata[iens].sm
    suz[:, iens]   = mdata[iens].suz
    slz[:, iens]   = mdata[iens].slz
    st_uh[:, iens] = mdata[iens].st_uh

  end

  # Run ensemble kalman filter

  sm    = enkf(sm, obs_ens, q_sim)
  suz   = enkf(suz, obs_ens, q_sim)
  slz   = enkf(slz, obs_ens, q_sim)
  st_uh = enkf(st_uh, obs_ens, q_sim)

  # Check limits of states

  sm[sm .< 0] = 0.
  sm[sm .> mdata[1].param[1]] = mdata[1].param[1]

  suz[suz .< 0] = 0.
  slz[slz .< 0] = 0.
  st_uh[st_uh .< 0] = 0.

  # Add arrays to states

  for iens = 1:nens

    mdata[iens].sm = sm[:, iens][1]
    mdata[iens].suz = suz[:, iens][1]
    mdata[iens].slz = slz[:, iens][1]
    mdata[iens].st_uh = st_uh[:, iens]

  end

end


"""
    run_timestep(mdata::Hbv)

Propagate the model one time step and return simulated dischage.
"""
function run_timestep(mdata::Hbv)

  # mdata and parameters

  sm = mdata.sm
  suz = mdata.suz
  slz = mdata.slz
  st_uh = mdata.st_uh
  hbv_ord = mdata.hbv_ord
  epot = mdata.epot
  prec = mdata.prec

  fc     = mdata.param[1]
  lp     = mdata.param[2]
  k0     = mdata.param[3]
  k1     = mdata.param[4]
  k2     = mdata.param[5]
  beta   = mdata.param[6]
  perc   = mdata.param[7]
  ulz    = mdata.param[8]
  maxbas = mdata.param[9]

  # Input for current time step

  prec_now = prec
  epot_now = epot

  # Soil moisture zone (assume no evaporation during rainfall)

  if prec_now > 0.

    # Beta function

    f_recharge = (sm / fc) ^ beta

    # Groundwater recharge

    recharge = f_recharge * prec_now

    # Update soil moisture zone

    sm = sm + prec_now - recharge

    # Add excess soil moisture to groundwater recharge

    if sm > fc
      recharge += sm - fc
      sm = fc
    end

    # No evapotranspiration

    eact = 0.

  else

    # Compute actual evapotranspiration

    eact = epot_now * min(sm/(fc*lp), 1.)

    # Update soil moisture zone

    sm = sm - eact

    # Check limits for soil moisture zone

    if sm < 0.
      eact = max(eact + sm, 0.)
      sm = 0.
    end

    # No groundwater recharge

    recharge = 0.

  end

  # Add recharge to upper groundwater box

  suz = suz + recharge

  # Remove percolation from upper groundwater box

  perc_now = min(perc, suz)

  suz = suz - perc_now

  # Compute runoff from upper groundwater box and update storage

  q_suz = k1 * suz + k0 * max(suz-ulz, 0.)

  suz = suz - q_suz

  if suz < 0.
    q_suz = max(q_suz + suz, 0.)
    suz = 0.
  end

  # Add precolation to lower groundwater box

  slz = slz + perc_now

  # Compute runoff from lower groundwater box and update storage

  q_slz = k2 * slz

  slz = slz - q_slz

  # Convolution of unit hydrograph

  q_tmp = q_suz + q_slz

  nh = length(hbv_ord)

  for k = 1:nh-1
    st_uh[k] = st_uh[k+1] + hbv_ord[k]*q_tmp
  end

  st_uh[nh] = hbv_ord[nh] * q_tmp

  # Compute total runoff

  q_tot = st_uh[1]

  # Assign states

  mdata.time  += Dates.Hour(mdata.tstep)
  mdata.sm = sm
  mdata.suz = suz
  mdata.slz = slz
  mdata.st_uh = st_uh
  mdata.q_sim = q_tot

  return nothing

end


# Function for computing ordinates of unit hydrograph

function compute_hbv_ord(maxbas)

  triang = Distributions.TriangularDist(0, maxbas)

  triang_cdf = Distributions.cdf(triang, 0:20)

  hbv_ord = diff(triang_cdf)

  return(hbv_ord)

end