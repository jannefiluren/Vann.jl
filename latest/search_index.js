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
    "text": "This package includes different model components for computing processes such as evapotranspiration, snow accumulation and melt, and routing of water through the subsurface. The model blocks can be combined in arbritraty combinations. The package additionally includes different additions, such as data assimilation procedures for updating the state variables of the hydrological models."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "Install the package using:Pkg.clone(\"https://github.com/jmgnve/Vann.jl.git\")"
},

{
    "location": "index.html#Input-variables-1",
    "page": "Home",
    "title": "Input variables",
    "category": "section",
    "text": "Input variables depending on the length of the time step, such as precipitation, should given in units mm/timestep For all models, the time step should be given in hours."
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
    "text": "The following rainfall-runoff models are currently included in the package. They can be combined with different snow models.GR4JPerrin, Charles, Claude Michel, and Vazken Andréassian. 2003. “Improvement of a Parsimonious Model for Streamflow Simulation.” Journal of Hydrology 279 (1-4): 275–89. doi:10.1016/S0022-1694(03)00225-7.HBVSeibert, J., and M. J. P. Vis (2012), Teaching hydrological modeling with a user-friendly catchment-runoff-model software package, Hydrol.Earth Syst. Sci., 16(9), 3315–3325."
},

{
    "location": "hyd_models.html#Model-initialization-1",
    "page": "Hydrological models",
    "title": "Model initialization",
    "category": "section",
    "text": "The following examples shows how to initialize the GR4J model.# Load packages \n\nusing Vann\n\n# Model time step\n\ntstep = 24.0\n\n# Initial date of the simulation period\n\ntime = DateTime(2000, 1, 1)\n\n# Initilize the model with predefined parameters\n\nmodel_var = Gr4j(tstep, time)\n\n# Initilize the model with custom parameters\n\nparam = [257.238, 1.012, 88.235, 2.208]\n\nmodel_var = Gr4j(tstep, time, param)"
},

{
    "location": "hyd_models.html#Run-the-model-1",
    "page": "Hydrological models",
    "title": "Run the model",
    "category": "section",
    "text": "The following example shows how to run the GR4J model.# Load packages\n\nusing Vann\n\n# Read example input data\n\nfilename = joinpath(Pkg.dir(\"Vann\"), \"data\", \"airgr\", \"test_data.txt\")\n\ndata = readdlm(filename, ',', header = true)\n\nprec  = data[1][:,1]\nepot  = data[1][:,2]\nq_obs = data[1][:,3]\n\nprec = transpose(prec)\nepot = transpose(epot)\n\nparam  = [257.238, 1.012, 88.235, 2.208]\n\ntstep = 24.0\n\ntime = DateTime(2000,1,1)\n\n# Select model\n\nmodel_var = Gr4j(tstep, time, param)\n\n# Run model - output is watershed discharge\n\nq_sim = run_model(model_var, prec, epot)"
},

{
    "location": "snow_models.html#",
    "page": "Snow models",
    "title": "Snow models",
    "category": "page",
    "text": ""
},

{
    "location": "snow_models.html#Snow-models-1",
    "page": "Snow models",
    "title": "Snow models",
    "category": "section",
    "text": "The following snow models are currently included in the package.TinBasicSimple temperature-index snow melt model with constant degree-day factor.TinStandardMagnusson, J., D. Gustafsson, F. Husler, and T. Jonas (2014), Assimilation of point SWE data into a distributed snow cover model comparing two contrasting methods, Water Resour. Res., 50, doi:10.1002/2014WR015302."
},

{
    "location": "snow_models.html#Model-initialization-1",
    "page": "Snow models",
    "title": "Model initialization",
    "category": "section",
    "text": "The following examples shows how to initialize the TinBasic model.# Load packages\n\nusing Vann\n\n# Model time step\n\ntstep = 24.0\n\n# Initial date of the simulation period\n\ntime = DateTime(2000, 1, 1)\n\n# Fraction covered by the different elevation bands\n\nfrac = [0.5; 0.5]\n\n# Initilize the model with predefined parameters\n\nmodel_var = TinBasic(tstep, time, frac)\n\n# Initilize the model with custom parameters\n\nparam = [0.5, 4.0, 1.2]\n\nmodel_var = TinBasic(tstep, time, param, frac)"
},

{
    "location": "snow_models.html#Run-the-model-1",
    "page": "Snow models",
    "title": "Run the model",
    "category": "section",
    "text": "The following example shows how to run the TinBasic model.# Load packages\n\nusing Vann\n\n# Read example input data\n\nfilepath = joinpath(Pkg.dir(\"Vann\"), \"data\", \"atnasjo\")\n\ndate, tair, prec, q_obs, frac = load_data(filepath, \"Q_ref.txt\")\n\ntstep = 24.0\n\ntime = date[1]\n\n# Select model\n\nmodel_var = TinBasic(tstep, time, frac)\n\n# Run model - output is snowmelt runoff\n\nq_sim = run_model(model_var, date, tair, prec)"
},

{
    "location": "calibration.html#",
    "page": "Model calibration",
    "title": "Model calibration",
    "category": "page",
    "text": ""
},

{
    "location": "calibration.html#Model-calibration-1",
    "page": "Model calibration",
    "title": "Model calibration",
    "category": "section",
    "text": "The following example illustrates how to calibrate a complete hydrological model, including the snow model and runoff generating part.# Load packages\n\nusing Vann\n\n# Read example input data\n\nfilepath = joinpath(Pkg.dir(\"Vann\"), \"data\", \"atnasjo\")\n\ndate, tair, prec, q_obs, frac = load_data(filepath, \"Q_ref.txt\")\n\n# Compute potential evapotranspiration\n\nepot = epot_zero(date)\n\n# Select model\n\ntstep = 24.0\n\nst_snow = TinBasic(tstep, date[1], frac)\nst_hydro = Gr4j(tstep, date[1])\n\n# Run calibration\n\nparam_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs; warmup = 1)"
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
    "text": "The package contains two classical data assimilation methods: the ensemble Kalman filter and the particle filter. Both filter can be used with any combinations of the snow and hydrological models. Select the ensemble Kalman filter using enkf_filter and the particle filter using particle_filter."
},

{
    "location": "data_assim.html#Filter-example-1",
    "page": "Data assimilation",
    "title": "Filter example",
    "category": "section",
    "text": "using Vann\nusing DataAssim\nusing PyPlot\n\n# Model choices\n\nsnow_choice = TinBasic\nhydro_choice = Gr4j\n\n# Filter choices\n\nfilter_choice = enkf_filter\n\nnens = 500\n\n# Load data\n\npath_inputs = Pkg.dir(\"Vann\", \"data/atnasjo\")\n\ndate, tair, prec, q_obs, frac = load_data(path_inputs)\n\n# Compute potential evapotranspiration\n\nepot = epot_zero(date)\n\n# Initilize model\n\ntstep = 24.0\n\nst_snow = eval(Expr(:call, snow_choice, tstep, date[1], frac))\nst_hydro = eval(Expr(:call, hydro_choice, tstep, date[1]))\n\n# Run calibration\n\nparam_snow, param_hydro = run_model_calib(st_snow, st_hydro, date, tair, prec, epot, q_obs)\n\n# Run model and filter\n\nst_snow = eval(Expr(:call, snow_choice, tstep, date[1], param_snow, frac))\nst_hydro = eval(Expr(:call, hydro_choice, tstep,  date[1], param_hydro))\n\nq_res = eval(Expr(:call, filter_choice, st_snow, st_hydro, prec, tair, epot, q_obs, nens))\n\n# Plot results\n\nfig = figure(figsize = (12,7))\nplot(date, q_obs, linewidth = 1.2, color = \"k\", label = \"Observed\", zorder = 1)\nfill_between(date, q_res[:, 3], q_res[:, 2], facecolor = \"r\", edgecolor = \"r\", label = \"Simulated\", alpha = 0.55, zorder = 2)\nlegend()"
},

]}
