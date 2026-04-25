defmodule Zung.MixProject do
  use Mix.Project

  def project do
    [
      app: :zung,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: [
        plt_file: {:no_warnings, "priv/plts/dialyzer.plt"},
        flags: [:error_handling, :unknown, :unmatched_returns, :extra_return, :missing_return]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Zung.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:gproc, "~> 0.9.0"},
      {:mecks_unit, "~> 0.1.9", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
