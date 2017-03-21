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
    "location": "hyd_models.html#Hydrological-model-components-1",
    "page": "Hydrological models",
    "title": "Hydrological model components",
    "category": "section",
    "text": ""
},

{
    "location": "hyd_models.html#GR4J-model-1",
    "page": "Hydrological models",
    "title": "GR4J model",
    "category": "section",
    "text": "Gr4j\nGr4j()\nGr4j(param)\nget_param_range(mdata::Gr4j)\ninit_states(mdata::Gr4j)\nassign_param(mdata::Gr4j, param::Array{Float64,1})\nhydro_model(mdata::Gr4j)"
},

{
    "location": "hyd_models.html#HBV-model-1",
    "page": "Hydrological models",
    "title": "HBV model",
    "category": "section",
    "text": ""
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
