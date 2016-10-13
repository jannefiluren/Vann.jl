

# Type definitions

type HbvType <: HydroType

  sm::Float64
  suz::Float64
  slz::Float64
  st_uh::Array{Float64,1}
  hbv_ord::Array{Float64,1}
  epot::Float64
  infilt::Float64
  param::Array{Float64,1}
  frac::Array{Float64,1}

end


# Outer constructors

function HbvType(frac)

  nzones  = length(frac);

  sm      = 0.;
  suz     = 0.;
  slz     = 0.;
  st_uh   = zeros(Float64, 20);

  epot   = 0.0;
  infilt = 0.0;

  # fc, lp, k0, k1, k2, beta, perc, ulz, maxbas

  param = [100., 0.8, 0.05, 0.05, 0.01, 1., 2., 30., 2.5];

  hbv_ord = compute_hbv_ord(param[9]);

  HbvType(sm, suz, slz, st_uh, hbv_ord, epot, infilt, param, frac);

end

function HbvType(param, frac)

  nzones  = length(frac);

  sm      = 0.;
  suz     = 0.;
  slz     = 0.;
  st_uh   = zeros(Float64, 20);

  epot   = 0.0;
  infilt = 0.0;

  hbv_ord = compute_hbv_ord(param[9]);

  HbvType(sm, suz, slz, st_uh, hbv_ord, epot, infilt, param, frac);

end


# Parameter ranges for calibration

function get_param_range(States::HbvType)

  param_range_hydro = [(1., 1000.), (0.5, 0.99), (0.001, 0.999),
                       (0.001, 0.999), (0.001, 0.999), (1., 5.),
                       (0.1, 1000.), (1., 1000.), (1., 20.)];

end


# Initilize state variables

function init_states(States::HbvType)

  States.sm      = 0.;
  States.suz     = 0.;
  States.slz     = 0.;

  for i in eachindex(States.st_uh)
    States.st_uh[i] = 0.;
  end

end


# Assign parameter values

function assign_param(States::HbvType, param::Array{Float64,1})

  for i in eachindex(States.param)
    States.param[i] = param[i];
  end

  States.hbv_ord = compute_hbv_ord(param[9]);

end


# Function for computing ordinates of unit hydrograph

function compute_hbv_ord(maxbas)

  triang = TriangularDist(0, maxbas);

  triang_cdf = cdf(triang, 0:20);

  hbv_ord = diff(triang_cdf);

  return(hbv_ord);

end


# Function for HBV model

function hydro_model(States::HbvType)

  # States and parameters

  sm = States.sm;
  suz = States.suz;
  slz = States.slz;
  st_uh = States.st_uh;
  hbv_ord = States.hbv_ord;
  epot = States.epot;
  infilt = States.infilt;
  #param = States.param;

  fc     = States.param[1];
  lp     = States.param[2];
  k0     = States.param[3];
  k1     = States.param[4];
  k2     = States.param[5];
  beta   = States.param[6];
  perc   = States.param[7];
  ulz    = States.param[8];
  maxbas = States.param[9];

  # Input for current time step

  prec_now = infilt;
  epot_now = epot;

  # Soil moisture zone (assume no evaporation during rainfall)

  if prec_now > 0.

    # Beta function

    f_recharge = (sm / fc) ^ beta;

    # Groundwater recharge

    recharge = f_recharge * prec_now;

    # Update soil moisture zone

    sm = sm + prec_now - recharge;

    # Add excess soil moisture to groundwater recharge

    if sm > fc
      recharge += sm - fc;
      sm = fc;
    end

    # No evapotranspiration

    eact = 0.;

  else

    # Compute actual evapotranspiration

    eact = epot_now * min(sm/(fc*lp), 1.)

    # Update soil moisture zone

    sm = sm - eact;

    # Check limits for soil moisture zone

    if sm < 0.
      eact = max(eact + sm, 0.);
      sm = 0.;
    end

    # No groundwater recharge

    recharge = 0.;

  end

  # Add recharge to upper groundwater box

  suz = suz + recharge;

  # Remove percolation from upper groundwater box

  perc_now = min(perc, suz);

  suz = suz - perc_now;

  # Compute runoff from upper groundwater box and update storage

  q_suz = k1 * suz + k0 * max(suz-ulz, 0.);

  suz = suz - q_suz;

  if suz < 0.
    q_suz = max(q_suz + suz, 0.);
    suz = 0.;
  end

  # Add precolation to lower groundwater box

  slz = slz + perc_now;

  # Compute runoff from lower groundwater box and update storage

  q_slz = k2 * slz;

  slz = slz - q_slz;

  # Convolution of unit hydrograph

  q_tmp = q_suz + q_slz;

  nh = length(hbv_ord);

  for k = 1:nh-1
    st_uh[k] = st_uh[k+1] + hbv_ord[k]*q_tmp;
  end

  st_uh[nh] = hbv_ord[nh] * q_tmp;

  # Compute total runoff

  q_tot = st_uh[1];

  # Assign states

  States.sm = sm;
  States.suz = suz;
  States.slz = slz;
  States.st_uh = st_uh;

  # Return discharge

  return(q_tot);

end
