
"""
The Gr4j type contains the state variables (st, st_uh1, st_uh2), the inputs
(epot, prec) for one time step, the parameters (param) and the time step
length (tstep) for the GR4J model.
"""
type Gr4j <: Hydro

  st::Array{Float64,1}
  st_uh1::Array{Float64,1}
  st_uh2::Array{Float64,1}
  ord_uh1::Array{Float64,1}
  ord_uh2::Array{Float64,1}
  epot::Float64
  prec::Float64
  q_sim::Float64
  param::Array{Float64,1}
  tstep::Float64

end


"""
    Gr4j(tstep)
Constructor for GR4J with predefined state variables, parameters and inputs.
The time step (tstep) is given as a fraction of one day. Thus, for hourly input
data tstep should be set to 1/24.
"""
function Gr4j(tstep)

  n_ord = ceil(Int64, 20.0 * 24.0 / tstep)

  st      = zeros(Float64, 2)
  st_uh1  = zeros(Float64, n_ord)
  st_uh2  = zeros(Float64, 2 * n_ord)
  ord_uh1 = zeros(Float64, n_ord)
  ord_uh2 = zeros(Float64, 2 * n_ord)

  epot = 0.0
  prec = 0.0

  q_sim = 0.0

  param  = [257.238, 1.012, 88.235, 2.208]

  st[1] = 0.3 * param[1]
  st[2] = 0.5 * param[3]

  D = 1.30434782 * (tstep / 24.0) + 1.19565217

  UH1(ord_uh1, param[4] * 24.0 / tstep, D)
  UH2(ord_uh2, param[4] * 24.0 / tstep, D)

  Gr4j(st, st_uh1, st_uh2, ord_uh1, ord_uh2, epot, prec, q_sim, param, tstep)

end


"""
    Gr4j(tstep, param)
Constructor for GR4J with predefined state variables and inputs. The parameter
values are given as input. The time step (tstep) is given as a fraction of one
day. Thus, for hourly input data tstep should be set to 1/24.
"""
function Gr4j(tstep, param)

  n_ord = ceil(Int64, 20.0 * 24.0 / tstep)

  st      = zeros(Float64, 2)
  st_uh1  = zeros(Float64, n_ord)
  st_uh2  = zeros(Float64, 2 * n_ord)
  ord_uh1 = zeros(Float64, n_ord)
  ord_uh2 = zeros(Float64, 2 * n_ord)

  st[1] = 0.3 * param[1]
  st[2] = 0.5 * param[3]

  D = 1.30434782 * (tstep / 24.0) + 1.19565217

  UH1(ord_uh1, param[4] * 24.0 / tstep, D)
  UH2(ord_uh2, param[4] * 24.0 / tstep, D)

  epot = 0.0
  prec = 0.0

  q_sim = 0.0

  Gr4j(st, st_uh1, st_uh2, ord_uh1, ord_uh2, epot, prec, q_sim, param, tstep)

end


"""
    init_states(mdata::Gr4j)
Initilize the state variables of the model.
"""
function init_states(mdata::Gr4j)

  mdata.st[1] = 0.3 * mdata.param[1]
  mdata.st[2] = 0.5 * mdata.param[3]

  for i in eachindex(mdata.st_uh1)
    mdata.st_uh1[i] = 0.
  end

  for i in eachindex(mdata.st_uh2)
    mdata.st_uh2[i] = 0.
  end

end


"""
    get_param_range(mdata::Gr4j)
Get allowed parameter ranges for the calibration of the model.
"""
function get_param_range(mdata::Gr4j)

  param_range_hydro = [(1.0, 20000.0), (-100.0, 100.0), (1.0, 20000.0), (0.5, 10.0)]

end


"""
    assign_param(mdata::Gr4j, param::Array{Float64,1})
Assign parameter values to the Gr4j type.
"""
function assign_param(mdata::Gr4j, param::Array{Float64,1})

  for i in eachindex(mdata.param)
    mdata.param[i] = param[i]
  end

  D = 1.30434782 * (mdata.tstep / 24.0) + 1.19565217

  UH1(mdata.ord_uh1, param[4] * 24.0 / mdata.tstep, D)
  UH2(mdata.ord_uh2, param[4] * 24.0 / mdata.tstep, D)

end


"""
    get_states(hydro_out::Array{Gr4j,1})
Get state variables
"""
function get_states(hydro_out::Array{Gr4j,1})

  states = zeros(length(hydro_out), 2)

  for i in 1:length(hydro_out)

    states[i, 1] = hydro_out[i].st[1]
    states[i, 2] = hydro_out[i].st[2]

  end

  return states

end



"""
    enkf_hydro(mdata::Array{Gr4j,1}, obs_ens, q_sim)
Implementation of the ensemble Kalman filter for the GR4J model.
"""
function enkf_hydro(mdata::Array{Gr4j,1}, obs_ens, q_sim)

  nens = length(mdata)

  # Allocate arrays

  st     = zeros(Float64, length(mdata[1].st), nens)
  st_uh1 = zeros(Float64, length(mdata[1].st_uh1), nens)
  st_uh2 = zeros(Float64, length(mdata[1].st_uh2), nens)

  # Add states to arrays

  for iens = 1:nens

    st[:, iens]     = mdata[iens].st
    st_uh1[:, iens] = mdata[iens].st_uh1
    st_uh2[:, iens] = mdata[iens].st_uh2

  end

  # Run ensemble kalman filter

  st     = enkf(st, obs_ens, q_sim)
  st_uh1 = enkf(st_uh1, obs_ens, q_sim)
  st_uh2 = enkf(st_uh2, obs_ens, q_sim)

  # Check limits of states

  st[st .< 0] = 0.
  st_uh1[st_uh1 .< 0] = 0.
  st_uh2[st_uh2 .< 0] = 0.

  st[1, st[1, :] .> mdata[1].param[1]] = mdata[1].param[1]
  st[2, st[2, :] .> mdata[1].param[3]] = mdata[1].param[3]

  # Add arrays to states

  for iens = 1:nens

    mdata[iens].st = st[:, iens]
    mdata[iens].st_uh1 = st_uh1[:, iens]
    mdata[iens].st_uh2 = st_uh2[:, iens]

  end

  nothing

end


"""
    run_timestep(mdata::Gr4j)
Propagate the model one time step and return simulated dischage.
"""
function run_timestep(mdata::Gr4j)

  St     = mdata.st
  StUH1  = mdata.st_uh1
  StUH2  = mdata.st_uh2
  OrdUH1 = mdata.ord_uh1
  OrdUH2 = mdata.ord_uh2
  Param  = mdata.param
  P1     = mdata.prec
  E      = mdata.epot
  tstep  = mdata.tstep

  A = Param[1]
  B = 0.9

  # Interception and production store

  if P1 <= E
    EN = E - P1
    PN = 0.0
    WS = EN / A
    if WS > 13.0
      WS = 13.0
    end
    TWS = tanh(WS)
    Sr = St[1] / A
    ER = St[1] * (2.0-Sr)*TWS/(1.0+(1.0-Sr)*TWS)
    AE = ER + P1
    St[1] = St[1] - ER
    PR = 0.0
  else
    EN = 0.0
    AE = E
    PN = P1 - E
    WS = PN / A
    if WS > 13.0
      WS = 13.0
    end
    TWS = tanh(WS)
    Sr = St[1] / A
    PS = A*(1.0-Sr*Sr)*TWS/(1.0+Sr*TWS)
    PR = PN - PS
    St[1] = St[1] + PS
  end

  # Percolation from production store

  if St[1] < 0.0
    St[1] = 0.0
  end

  scale_param = 25.62891 * (24.0 / tstep)

  Sr = St[1] / Param[1]
  Sr = Sr * Sr
  Sr = Sr * Sr
  PERC = St[1] * (1.0-1.0/sqrt(sqrt(1.0 + Sr/scale_param)))

  St[1] = St[1] - PERC

  PR = PR + PERC

  # Split of effective rainfall into the two routing components

  PRHU1 = PR * B
  PRHU2 = PR * (1.0-B)

  # Convolution of unit hydrograph UH1

  NH = length(OrdUH1)

  for K = 1:NH-1
    StUH1[K] = StUH1[K+1] + OrdUH1[K]*PRHU1
  end

  StUH1[NH] = OrdUH1[NH] * PRHU1

  # Convolution of unit hydrograph UH2

  NH = length(OrdUH2)

  for K = 1:NH-1
    StUH2[K] = StUH2[K+1] + OrdUH2[K]*PRHU2
  end

  StUH2[NH] = OrdUH2[NH] * PRHU2

  # Potential intercatchment semi-exchange

  scale_param = (tstep / 24.0)

  Rr = St[2]/Param[3]
  EXCH = scale_param * Param[2]*Rr*Rr*Rr*sqrt(Rr)

  # Routing store

  AEXCH1 = EXCH

  if (St[2]+StUH1[1]+EXCH) < 0.0
    AEXCH1 = -St[2] - StUH1[1]
  end

  St[2] = St[2] + StUH1[1] + EXCH

  if St[2] < 0.0
    St[2] = 0.0
  end

  scale_param = (24.0 / tstep)
  Rr = St[2]^4 / (Param[3]^4 * scale_param)

  QR = St[2] * (1.0-1.0/sqrt(sqrt(1.0+Rr)))

  St[2] = St[2] - QR

  # Runoff from direct branch QD

  AEXCH2 = EXCH

  if (StUH2[1]+EXCH) < 0.0
    AEXCH2 = -StUH2[1]
  end

  QD = max(0.0,StUH2[1]+EXCH)

  # Total runoff

  Q = QR + QD

  if Q < 0.0
    Q = 0.0
  end

  mdata.st      = St
  mdata.st_uh1  = StUH1
  mdata.st_uh2  = StUH2
  mdata.ord_uh1 = OrdUH1
  mdata.ord_uh2 = OrdUH2
  mdata.q_sim   = Q

  return nothing

end


function SS1(I,C,D)

  FI = I
  if FI <= 0.0
    SS1 = 0.0
  elseif FI < C
    SS1 = (FI/C)^D
  else
    SS1 = 1.0
  end

end


function SS2(I,C,D)

  FI = I
  if FI <= 0.0
    SS2 = 0.0
  elseif FI <= C
    SS2 = 0.5*(FI/C)^D
  elseif FI < 2.0*C
    SS2 = 1.0-0.5*(2.0-FI/C)^D
  else
    SS2=1.0
  end

end


function UH1(OrdUH1,C,D)

  NH = length(OrdUH1)

  for I in 1:NH

    OrdUH1[I] = SS1(I,C,D)-SS1(I-1,C,D)

  end

end


function UH2(OrdUH2,C,D)

  NH = length(OrdUH2)

  for I in 1:NH

    OrdUH2[I] = SS2(I,C,D)-SS2(I-1,C,D)

  end

end


#**********************************************************************
#     SUBROUTINE MOD_GR4J(St,StUH1,StUH2,OrdUH1,OrdUH2,Param,P1,E,Q)
# Run on a single time step with the GR4J model
# Inputs:
#       St     Vector of model states in stores at the beginning of the time step [mm]
#       StUH1  Vector of model states in Unit Hydrograph 1 at the beginning of the time step [mm]
#       StUH2  Vector of model states in Unit Hydrograph 2 at the beginning of the time step [mm]
#       OrdUH1 Vector of ordinates in UH1 [-]
#       OrdUH2 Vector of ordinates in UH2 [-]
#       Param  Vector of model parameters [various units]
#       P1     Value of rainfall during the time step [mm/day]
#       E      Value of potential evapotranspiration during the time step [mm/day]
# Outputs:
#       St     Vector of model states in stores at the end of the time step [mm]
#       StUH1  Vector of model states in Unit Hydrograph 1 at the end of the time step [mm]
#       StUH2  Vector of model states in Unit Hydrograph 2 at the end of the time step [mm]
#       Q      Value of simulated flow at the catchment outlet for the time step [mm]
#**********************************************************************

#**********************************************************************
#     FUNCTION SS1(I,C,D)
# Values of the S curve (cumulative HU curve) of GR unit hydrograph UH1
# Inputs:
#    C: time constant
#    D: exponent
#    I: time-step
# Outputs:
#    SS1: Values of the S curve for I
#**********************************************************************

#**********************************************************************
#     FUNCTION SS2(I,C,D)
# Values of the S curve (cumulative HU curve) of GR unit hydrograph UH2
# Inputs:
#    C: time constant
#    D: exponent
#    I: time-step
# Outputs:
#    SS2: Values of the S curve for I
#**********************************************************************

#**********************************************************************
#     SUBROUTINE UH1(OrdUH1,C,D)
# Computation of ordinates of GR unit hydrograph UH1 using successive differences on the S curve SS1
# Inputs:
#    C: time constant
#    D: exponent
# Outputs:
#    OrdUH1: NH ordinates of discrete hydrograph
#**********************************************************************

#**********************************************************************
#     SUBROUTINE UH2(OrdUH2,C,D)
# Computation of ordinates of GR unit hydrograph HU2 using successive differences on the S curve SS2
# Inputs:
#    C: time constant
#    D: exponent
# Outputs:
#    OrdUH2: 2*NH ordinates of discrete hydrograph
#**********************************************************************
