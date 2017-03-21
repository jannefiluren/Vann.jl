"""
Type definition for HBV model.
"""
type Hbv <: Hydro

  sm::Float64
  suz::Float64
  slz::Float64
  st_uh::Array{Float64,1}
  hbv_ord::Array{Float64,1}
  epot::Float64
  infilt::Float64
  param::Array{Float64,1}
  tstep::Float64

end


# Outer constructors

function Hbv(tstep)

  # Parameters: fc, lp, k0, k1, k2, beta, perc, ulz, maxbas

  param = [100., 0.8, 0.05, 0.05, 0.01, 1., 2., 30., 2.5]

  # Unit hydrograph ordinates

  hbv_ord = compute_hbv_ord(param[9], tstep)

  # States

  sm      = 0.
  suz     = 0.
  slz     = 0.
  st_uh   = zeros(Float64, length(hbv_ord))

  # Inputs

  epot   = 0.0
  infilt = 0.0

  Hbv(sm, suz, slz, st_uh, hbv_ord, epot, infilt, param, tstep)

end

function Hbv(tstep, param)

  # Unit hydrograph ordinates

  hbv_ord = compute_hbv_ord(param[9], tstep)

  # States

  sm      = 0.
  suz     = 0.
  slz     = 0.
  st_uh   = zeros(Float64, length(hbv_ord))

  # Inputs

  epot   = 0.0
  infilt = 0.0

  Hbv(sm, suz, slz, st_uh, hbv_ord, epot, infilt, param, tstep)

end


# Parameter ranges for calibration

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


# Initilize state variables

function init_states(mdata::Hbv)

  mdata.sm      = 0.
  mdata.suz     = 0.
  mdata.slz     = 0.

  for i in eachindex(mdata.st_uh)
    mdata.st_uh[i] = 0.
  end

end


# Assign parameter values

function assign_param(mdata::Hbv, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

  mdata.hbv_ord = compute_hbv_ord(param[9], mdata.tstep)
  mdata.st_uh   = zeros(Float64, length(mdata.hbv_ord))

end


# Function for computing ordinates of unit hydrograph

function compute_hbv_ord(maxbas, tstep)

  maxbas = maxbas / tstep

  triang = Distributions.TriangularDist(0, maxbas)

  triang_cdf = Distributions.cdf(triang, 0:ceil(Int64, maxbas + 2))

  hbv_ord = diff(triang_cdf)

  return(hbv_ord)

end


# Function for HBV model

function hydro_model(mdata::Hbv)

  # mdata and parameters

  sm = mdata.sm
  suz = mdata.suz
  slz = mdata.slz
  st_uh = mdata.st_uh
  hbv_ord = mdata.hbv_ord
  epot = mdata.epot
  infilt = mdata.infilt

  fc     = mdata.param[1]
  lp     = mdata.param[2]
  k0     = mdata.param[3]
  k1     = mdata.param[4]
  k2     = mdata.param[5]
  beta   = mdata.param[6]
  perc   = mdata.param[7] * mdata.tstep
  ulz    = mdata.param[8]
  maxbas = mdata.param[9]

  # Input for current time step

  prec_now = infilt
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

  mdata.sm = sm
  mdata.suz = suz
  mdata.slz = slz
  mdata.st_uh = st_uh

  # Return discharge

  return(q_tot)

end
