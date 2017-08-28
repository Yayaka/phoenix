# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env == :test do
  config :amorphos, :connection_protocols, %{
    "test" => %{module: Amorphos.TestConnection},
    "test-a" => %{module: Amorphos.ConnectionProviderTest.A},
    "test-b" => %{module: Amorphos.ConnectionProviderTest.B}}
  config :amorphos, service_protocols: %{
    "test" => %{module: Amorphos.TestMessageHandler},
    "test-answer-validation" => %{module: Amorphos.TestMessageHandler, answer_validation: true},
    "yayaka" => %{module: Amorphos.TestMessageHandler, answer_validation: true}}
end

config :amorphos, :workers,
  http: 10

config :guardian, Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "Amorphos",
  ttl: { 30, :days },
  allowed_drift: 2000,
  verify_issuer: true,
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "abcd",
  serializer: Amorphos.GuardianSerializer
