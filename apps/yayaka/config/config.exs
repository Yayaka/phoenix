use Mix.Config

config :yayaka, :message_handlers, %{
  "presentation" => %{module: YayakaPresentation.MessageHandler},
  "identity" => %{module: YayakaIdentity.MessageHandler},
  "repository" => %{module: YayakaRepository.MessageHandler},
  "social-graph" => %{module: YayakaSocialGraph.MessageHandler},
}
