defmodule FaultTree.MixProject do
  use Mix.Project

  def project do
    [
      app: :fault_tree,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:typed_struct, "~> 0.1.4"},
      {:decimal, "~> 1.7"},
      {:trot, "~> 0.7"},
      {:plug_cowboy, "~> 1.0"},
      {:poison, "~> 3.1.0"},
    ]
  end
end
