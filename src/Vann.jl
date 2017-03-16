module Vann

# using BlackBoxOptim
if is_windows()
	using NLopt
end
using Distributions

abstract HydroType
abstract SnowType

export HbvType, Gr4jType
export TinBasicType, TinStandardType

export hydro_model, snow_model
export load_data, crop_data
export get_param_range, init_states
export run_model_calib, calib_wrapper
export run_model
export assign_param
export get_input
export epot_zero, epot_monthly

include("hydro_hbv.jl")
include("hydro_gr4j.jl")
include("snow_tinbasic.jl")
include("snow_tinstandard.jl")
include("utils_data.jl")
include("utils_calib.jl")
include("utils_model.jl")
include("utils_epot.jl")

end
