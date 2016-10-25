module Vann

# using BlackBoxOptim
using NLopt
using Distributions

abstract HydroType
abstract SnowType

export HbvType, Gr4jType
export TinBasicType, TinStandardType

export hydro_model, snow_model
export resample, perturb_input
export load_data, crop_data
export get_param_range, init_states
export run_model_calib, calib_wrapper
export run_model
export assign_param
export get_input

include("hydro_hbv.jl")
include("hydro_gr4j.jl")
include("snow_tinbasic.jl")
include("snow_tinstandard.jl")
include("utils_pfilter.jl")
include("utils_data.jl")
include("utils_calib.jl")
include("utils_model.jl")

end
