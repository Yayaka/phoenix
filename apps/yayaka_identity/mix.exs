defmodule YayakaIdentity.Mixfile do
  use Mix.Project

  def project do
    [app: :yayaka_identity,
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

  def application do
    [extra_applications: [:logger],
     mod: {YayakaIdentity.Application, []}]
  end

  defp deps do
    [{:db, in_umbrella: true},
     {:ymp, in_umbrella: true},
     {:yayaka, in_umbrella: true},
     {:ex_json_schema, "~> 0.5.5"}]
  end
end
