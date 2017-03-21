var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Vann.jl-1",
    "page": "Home",
    "title": "Vann.jl",
    "category": "section",
    "text": "A Julia package for hydrological modelling."
},

{
    "location": "index.html#Package-Features-1",
    "page": "Home",
    "title": "Package Features",
    "category": "section",
    "text": "This package includes different model components for computing processes such as evapotranspiration, snow accumulation and melt, and routing of water through the subsurface. The model blocks can be combined in arbritraty combinations. The package additionally includes different data assimilation procedures for updating the state variables of the hydrological models."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "The package and so can be installed using:Pkg.clone(\"https://github.com/jmgnve/Vann.jl.git\")"
},

{
    "location": "index.html#Input-variables-1",
    "page": "Home",
    "title": "Input variables",
    "category": "section",
    "text": "Input variables depending on the length of the time step, such as precipitation, should given in units mm/timestep For all models, the time step should be relative to daily inputs. Thus, if hourly input data is used, the model time step should equal 1/24."
},

{
    "location": "hyd_models.html#",
    "page": "Hydrological models",
    "title": "Hydrological models",
    "category": "page",
    "text": ""
},

{
    "location": "hyd_models.html#Hydrological-models-1",
    "page": "Hydrological models",
    "title": "Hydrological models",
    "category": "section",
    "text": "The following rainfall-runoff models are currently included in the package. They can be combined with different snow models."
},

{
    "location": "hyd_models.html#Vann.Gr4j",
    "page": "Hydrological models",
    "title": "Vann.Gr4j",
    "category": "Type",
    "text": "The Gr4j type contains the state variables (st, st_uh1, st_uh2), the inputs (epot, infilt) for one time step, the parameters (param) and the time step length (tstep) for the GR4J model.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.Gr4j-Tuple{Any}",
    "page": "Hydrological models",
    "title": "Vann.Gr4j",
    "category": "Method",
    "text": "Gr4j(tstep)\n\nConstructor for GR4J with predefined state variables, parameters and inputs. The time step (tstep) is given as a fraction of one day. Thus, for hourly input data tstep should be set to 1/24.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.Gr4j-Tuple{Any,Any}",
    "page": "Hydrological models",
    "title": "Vann.Gr4j",
    "category": "Method",
    "text": "Gr4j(tstep, param)\n\nConstructor for GR4J with predefined state variables and inputs. The parameter values are given as input. The time step (tstep) is given as a fraction of one day. Thus, for hourly input data tstep should be set to 1/24.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.init_states-Tuple{Vann.Gr4j}",
    "page": "Hydrological models",
    "title": "Vann.init_states",
    "category": "Method",
    "text": "init_states(mdata::Gr4j)\n\nInitilize the state variables of the model.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.get_param_range-Tuple{Vann.Gr4j}",
    "page": "Hydrological models",
    "title": "Vann.get_param_range",
    "category": "Method",
    "text": "get_param_range(mdata::Gr4j)\n\nGet allowed parameter ranges for the calibration of the model.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.assign_param-Tuple{Vann.Gr4j,Array{Float64,1}}",
    "page": "Hydrological models",
    "title": "Vann.assign_param",
    "category": "Method",
    "text": "assign_param(mdata::Gr4j, param::Array{Float64,1})\n\nAssign parameter values to the Gr4j type.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.hydro_model-Tuple{Vann.Gr4j}",
    "page": "Hydrological models",
    "title": "Vann.hydro_model",
    "category": "Method",
    "text": "hydro_model(mdata::Gr4j)\n\nPropagate the model one time step and return simulated dischage.\n\n\n\n"
},

{
    "location": "hyd_models.html#GR4J-1",
    "page": "Hydrological models",
    "title": "GR4J",
    "category": "section",
    "text": "For details about this model, see the following publication:Perrin, Charles, Claude Michel, and Vazken Andréassian. 2003. “Improvement of a Parsimonious Model for Streamflow Simulation.” Journal of Hydrology 279 (1-4): 275–89. doi:10.1016/S0022-1694(03)00225-7.Gr4jThe following constructors are available for generating the types:Gr4j(tstep)\nGr4j(tstep, param)The following functions are mainly used during the calibration of the model:init_states(mdata::Gr4j)\nget_param_range(mdata::Gr4j)\nassign_param(mdata::Gr4j, param::Array{Float64,1})The models are written in state-space form. Calling the function below runs the model for one time step.hydro_model(mdata::Gr4j)"
},

{
    "location": "hyd_models.html#Vann.Hbv",
    "page": "Hydrological models",
    "title": "Vann.Hbv",
    "category": "Type",
    "text": "The Hbv type contains the state variables (sm, suz, slz, st_uh), the inputs (epot, infilt) for one time step, the parameters (param) and the time step length (tstep) for the HBV model.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.Hbv-Tuple{Any}",
    "page": "Hydrological models",
    "title": "Vann.Hbv",
    "category": "Method",
    "text": "Hbv(tstep)\n\nConstructor for HBV with predefined state variables, parameters and inputs. The time step (tstep) is given as a fraction of one day. Thus, for hourly input data tstep should be set to 1/24.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.Hbv-Tuple{Any,Any}",
    "page": "Hydrological models",
    "title": "Vann.Hbv",
    "category": "Method",
    "text": "Hbv(tstep, param)\n\nConstructor for HBV with predefined state variables and inputs. The parameter values are given as input. The time step (tstep) is given as a fraction of one day. Thus, for hourly input data tstep should be set to 1/24.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.init_states-Tuple{Vann.Hbv}",
    "page": "Hydrological models",
    "title": "Vann.init_states",
    "category": "Method",
    "text": "init_states(mdata::Hbv)\n\nInitilize the state variables of the model.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.get_param_range-Tuple{Vann.Hbv}",
    "page": "Hydrological models",
    "title": "Vann.get_param_range",
    "category": "Method",
    "text": "get_param_range(mdata::Hbv)\n\nGet allowed parameter ranges for the calibration of the model.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.assign_param-Tuple{Vann.Hbv,Array{Float64,1}}",
    "page": "Hydrological models",
    "title": "Vann.assign_param",
    "category": "Method",
    "text": "assign_param(mdata::Hbv, param::Array{Float64,1})\n\nAssign parameter values to the Hbv type.\n\n\n\n"
},

{
    "location": "hyd_models.html#Vann.hydro_model-Tuple{Vann.Hbv}",
    "page": "Hydrological models",
    "title": "Vann.hydro_model",
    "category": "Method",
    "text": "hydro_model(mdata::Hbv)\n\nPropagate the model one time step and return simulated dischage.\n\n\n\n"
},

{
    "location": "hyd_models.html#HBV-1",
    "page": "Hydrological models",
    "title": "HBV",
    "category": "section",
    "text": "For details about this model, see the following publication:Seibert, J., and M. J. P. Vis (2012), Teaching hydrological modeling with a user-friendly catchment-runoff-model software package, Hydrol.Earth Syst. Sci., 16(9), 3315–3325.HbvThe following constructors are available for generating the types:Hbv(tstep)\nHbv(tstep, param)The following functions are mainly used during the calibration of the model:init_states(mdata::Hbv)\nget_param_range(mdata::Hbv)\nassign_param(mdata::Hbv, param::Array{Float64,1})The models are written in state-space form. Calling the function below runs the model for one time step.hydro_model(mdata::Hbv)"
},

{
    "location": "data_assim.html#",
    "page": "Data assimilation",
    "title": "Data assimilation",
    "category": "page",
    "text": ""
},

{
    "location": "data_assim.html#Data-assimilation-methods-1",
    "page": "Data assimilation",
    "title": "Data assimilation methods",
    "category": "section",
    "text": ""
},

{
    "location": "data_assim.html#Ensemble-Kalman-filter-1",
    "page": "Data assimilation",
    "title": "Ensemble Kalman filter",
    "category": "section",
    "text": "An example"
},

{
    "location": "data_assim.html#Particle-filter-1",
    "page": "Data assimilation",
    "title": "Particle filter",
    "category": "section",
    "text": "An example"
},

]}
