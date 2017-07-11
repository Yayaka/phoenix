# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ymp, :connection_protocols, %{
  "https-token" => %{module: YMP.HTTPSTokenConnection}}

config :ymp, :service_protocols,
  %{"yayaka" => %{module: Yayaka.MessageHandler}}

if Mix.env == :test do
  config :ymp, :connection_protocols, %{
    "test" => %{module: YMP.TestConnection},
    "test-a" => %{module: YMP.ConnectionProviderTest.A},
    "test-b" => %{module: YMP.ConnectionProviderTest.B}}
  config :ymp, service_protocols:
    %{"test" => %{module: YMP.TestMessageHandler}}
end

config :ymp, :workers,
  http: 10

config :guardian, Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "YMP",
  ttl: { 30, :days },
  allowed_drift: 2000,
  verify_issuer: true,
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "abcd",
  serializer: YMP.GuardianSerializer
