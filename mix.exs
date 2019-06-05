defmodule FaultTree.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project() do
    [
      app: :fault_tree,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "FaultTree",
      source_url: "https://github.com/hexedpackets/fault_tree",
      docs: [main: "readme",
             extras: ["README.md"],
             source_ref: "v#{@version}",
             source_url: "https://github.com/hexedpackets/fault_tree"],
      description: description(),
      package: package(),
    ]
  end

  defp description() do
    """
    FaultTree is a library for performing [fault tree analysis](https://en.wikipedia.org/wiki/Fault_tree_analysis).
    It includes a small HTTP server capable of graphing the resulting FTA, or returning it as JSON.
    """
  end

  defp package() do
    [
      maintainers: ["William Huba"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/hexedpackets/fault_tree"},
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE lib config),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps() do
    [
      {:typed_struct, "~> 0.1.4"},
      {:decimal, "~> 1.7"},
      {:trot, "~> 0.7"},
      {:plug_cowboy, "~> 1.0"},
      {:poison, "~> 3.1.0"},
      {:sweet_xml, "~> 0.6.6"},

      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
    ]
  end
end
