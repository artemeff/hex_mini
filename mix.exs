defmodule HexMini.MixProject do
  use Mix.Project

  def project do
    [
      app: :hex_mini,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {HexMini.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:prod), do: ["lib", "rel/release_tasks"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:ecto_sql, "~> 3.0.0"},
      {:postgrex, "~> 0.14.0"},
      {:plug_cowboy, "~> 2.0"},
      {:hex_core, "~> 0.3"},
      {:jason, "~> 1.1"},
      {:distillery, "~> 2.0"},
      {:ex_machina, "~> 2.2", only: :test},
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
    ]
  end
end
