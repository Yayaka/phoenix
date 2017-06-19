use Mix.Config

config :yayaka,
  services: [:presentation, :identity, :repository, :social_graph],
  user_attribute_types: %{
    "yayaka" => ~w(name bio)
  },
  event_types: %{
    "yayaka" => ~w(post repost favorite delete-event)
  },
  content_types: %{
    "yayaka" => ~w(text)
  }

import_config "../apps/*/config/config.exs"
