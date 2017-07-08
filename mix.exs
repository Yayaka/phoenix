defmodule YayakaReference.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases()]
  end

  defp deps do
    []
  end

  defp aliases do
    [test: [&migrate/1, "test"]]
  end

  defp migrate(_) do
    System.cmd "mix", ["ecto.create", "--quiet"], cd: "apps/db", env: [{"MIX_ENV", "test"}]
    System.cmd "mix", ["ecto.migrate"], cd: "apps/db", env: [{"MIX_ENV", "test"}]
  end
end
