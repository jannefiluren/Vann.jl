using Documenter, Vann

makedocs(
  format = :html,
  sitename = "Vann.jl",
  authors = "Jan Magnusson",
  pages = [
    "Home" => "index.md"
  ]
)

deploydocs(
  repo  = "github.com/jmgnve/Vann.jl.git",
  target = "build",
  deps = nothing,
  make = nothing,
  julia = "0.5"
)
