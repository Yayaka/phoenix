defmodule YMP.Mixfile do
  use Mix.Project

  def project do
    [app: :ymp,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {YMP.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:db, in_umbrella: true},
     {:bypass, "~> 0.7", only: :test},
     {:guardian, "~> 0.14"},
     {:poison, "~> 3.1"},
     {:honeydew, "~> 1.0.0-rc7"},
     {:httpoison, "~> 0.12"},
     {:secure_random, "~> 0.5"},
     {:uuid, "~> 1.1"}]
  end
end
