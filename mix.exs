defmodule Zung.MixProject do
  use Mix.Project

  def project do
    [
      app: :zung,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Zung.Application, []}
    ]
  end

  defp deps do
    [
      {:gproc, "~> 0.9.0"},
      {:mecks_unit, "~> 0.1.9", only: :test}
    ]
  end
end
