defmodule YMP.Mixfile do
  use Mix.Project

  def project do
    [app: :ymp,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [applications: [:httpoison],
     extra_applications: [:logger],
     mod: {YMP.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ecto, "~> 2.1"},
     {:bypass, "~> 0.7", only: :test},
     {:guardian, "~> 0.14"},
     {:poison, "~> 3.1"},
     {:honeydew, "~> 1.0.0-rc7"},
     {:httpoison, "~> 0.12"},
     {:secure_random, "~> 0.5"}]
  end
end
