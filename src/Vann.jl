module Vann

using BlackBoxOptim
using Distributions
using DataAssim

abstract Hydro
abstract Snow

export Hbv, Gr4j
export TinBasic, TinStandard

export hydro_model, snow_model
export load_data, crop_data
export get_param_range, init_states
export run_model_calib, calib_wrapper
export run_model
export assign_param
export get_input
export epot_zero, epot_monthly
export particle_filter, enkf_filter
export split_prec, compute_ddf, pot_melt

include("models/gr4j.jl")
include("models/hbv.jl")
include("models/tinbasic.jl")
include("models/tinstandard.jl")
include("utils_calib.jl")
include("utils_data_assim.jl")
include("utils_data.jl")
include("utils_epot.jl")
include("utils_model.jl")
include("utils_snow.jl")

end
