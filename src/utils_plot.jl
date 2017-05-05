# Plot Gr4j

function plot_sim{T<:Gr4j}(hydro_out::Array{T,1}; q_obs = [], file_name = [])

  time  = [hydro_out[i].time for i in 1:length(hydro_out)]
  st1   = [hydro_out[i].st[1] for i in 1:length(hydro_out)]
  st2   = [hydro_out[i].st[2] for i in 1:length(hydro_out)]
  q_sim = [hydro_out[i].q_sim for i in 1:length(hydro_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  ax = plt[:subplot](211)
  plt[:plot](time, q_sim, linewidth = 1.2, color = "r", label = "Sim")
  plt[:title]("GR4J")
  plt[:ylabel]("Runoff")
  if ~isempty(q_obs)

    
    nse_res = round(nse(q_sim, q_obs), 2)
    kge_res = round(kge(q_sim, q_obs), 2)
    plt[:plot](time, q_obs, linewidth = 1.2, color = "b", label = "Obs")
    plt[:legend]()
    plt[:title]("GR4J | KGE = $(kge_res) | NSE = $(nse_res)")
  end

  plt[:subplot](212, sharex=ax)
  plt[:plot](time, st1, linewidth = 1.2, color = "k", label = "St1")
  plt[:plot](time, st2, linewidth = 1.2, color = "g", label = "St2")
  plt[:ylabel]("States (mm)")
  plt[:legend]()

  if ~isempty(file_name)
    savefig(file_name)
    close(fig)
  end

end


# Plot Hbv

function plot_sim{T<:Hbv}(hydro_out::Array{T,1}; q_obs = [], file_name = [])

  time = [hydro_out[i].time for i in 1:length(hydro_out)]
  sm   = [hydro_out[i].sm for i in 1:length(hydro_out)]
  suz  = [hydro_out[i].suz for i in 1:length(hydro_out)]
  slz  = [hydro_out[i].slz for i in 1:length(hydro_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  ax = plt[:subplot](211)
  plt[:plot](time, q_sim, linewidth = 1.2, color = "r")
  plt[:title]("HBV")
  plt[:ylabel]("Runoff")
  if ~isempty(q_obs)
    nse_res = round(nse(q_sim, q_obs), 2)
    kge_res = round(kge(q_sim, q_obs), 2)
    plt[:plot](time, q_obs, linewidth = 1.2, color = "b", label = "Obs")
    plt[:legend]()
    plt[:title]("GR4J | KGE = $(kge_res) | NSE = $(nse_res)")
  end  

  plt[:subplot](212, sharex = ax)
  plt[:plot](time, sm, linewidth = 1.2, color = "k", label = "SM")
  plt[:plot](time, suz, linewidth = 1.2, color = "b", label = "SUZ")
  plt[:plot](time, slz, linewidth = 1.2, color = "g", label = "SLZ")
  plt[:ylabel]("States (mm)")
  plt[:legend]()

  if ~isempty(file_name)
    savefig(file_name)
    close(fig)
  end

end


# Plot TinBasic

function plot_sim{T<:TinBasic}(snow_out::Array{T,1}; file_name = [])

  time = [snow_out[i].time for i in 1:length(snow_out)]
  swe  = [mean(snow_out[i].swe) for i in 1:length(snow_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  plt[:plot](time, swe, linewidth = 1.2, color = "b")
  plt[:title]("TinBasic")
  plt[:ylabel]("SWE (mm)")

  if ~isempty(file_name)
    savefig(file_name)
    close(fig)
  end

end


# Plot TinStandard

function plot_sim{T<:TinStandard}(snow_out::Array{T,1}; file_name = [])

  time = [snow_out[i].time for i in 1:length(snow_out)]
  swe  = [mean(snow_out[i].swe) for i in 1:length(snow_out)]
  lw   = [mean(snow_out[i].lw) for i in 1:length(snow_out)]

  fig = plt[:figure](figsize = (12,7))

  plt[:style][:use]("ggplot")

  ax = plt[:subplot](211)
  plt[:plot](time, swe, linewidth = 1.2, color = "b")
  plt[:ylabel]("SWE (mm)")
  plt[:title]("TinStandard")

  plt[:subplot](212, sharex = ax)
  plt[:plot](time, lw, linewidth = 1.2, color = "r")
  plt[:ylabel]("LW (mm)")

  if ~isempty(file_name)
    savefig(file_name)
    close(fig)
  end

end
