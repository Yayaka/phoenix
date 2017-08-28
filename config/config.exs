use Mix.Config

max_timeline_subscription_length = 43200 # 12 hours
max_notification_subscription_length = 43200

yayaka = %{
  name: "yayaka",
  version: "0.1.0",
  services: [:presentation, :identity, :repository, :social_graph],
  parameters: %{
    subprotocols: [%{
      "name" => "yayaka",
      "version" => "0.1.0",
      "user-attributes" => ~w(service-labels
                              subscriber-hosts
                              publisher-hosts
                              primary-publisher-host
                              primary-repository-host
                              primary-notification-host
                              repository-subscriptions
                              biography links icon name),
      "event-types" => ~w(post repost reply quote follow
                          delete-post update-post),
      "content-types" => ~w(plaintext),
      "notification-types" => ~w(follow reply repost quote),
      "parameters" => %{
        "max-timeline-subscription-length" => %{
          "seconds" => max_timeline_subscription_length},
        "max-notification-subscription-length" => %{
          "seconds" => max_notification_subscription_length}
      }
    }]
  }
}

https_token = %{
  name: "https-token",
  version: "0.1.0",
  parameters: %{
    "request-path" => "/api/amorphos/https-token/request",
    "grant-path" => "/api/amorphos/https-token/grant",
    "packet-path" => "/api/amorphos/https-token/packet"
  }
}

config :amorphos, :host_information, %{
  "amorphos-version" => "0.1.0",
  "connection-protocols" => [https_token],
  "service-protocols" => [yayaka]
}

config :amorphos, HTTPSTokenConnection, https_token

reducer = fn subprotocol, {user_attributes, event_types, content_types, notification_types} ->
  name = subprotocol["name"]
  user_attributes = Map.put(user_attributes, name, subprotocol["user-attributes"])
  event_types = Map.put(event_types, name, subprotocol["event-types"])
  content_types = Map.put(content_types, name, subprotocol["content-types"])
  notification_types = Map.put(notification_types, name, subprotocol["notification-types"])
  {user_attributes, event_types, content_types, notification_types}
end
{user_attributes,
  event_types,
  content_types,
  notification_types} = Enum.reduce(yayaka.parameters.subprotocols, {%{}, %{}, %{}, %{}}, reducer)

config :yayaka,
  services: yayaka.services,
  user_attributes: user_attributes,
  event_types: event_types,
  content_types: content_types,
  notification_types: notification_types,
  max_timeline_subscription_length: max_timeline_subscription_length,
  max_notification_subscription_length: max_notification_subscription_length

config :amorphos, :connection_protocols, %{
  "https-token" => %{module: YMP.HTTPSTokenConnection}}

config :amorphos, :service_protocols,
  %{"yayaka" => %{module: Yayaka.MessageHandler, answer_validation: true}}

config :yayaka, :message_handlers, %{
  "presentation" => %{module: YayakaPresentation.MessageHandler},
  "identity" => %{module: YayakaIdentity.MessageHandler},
  "repository" => %{module: YayakaRepository.MessageHandler},
  "social-graph" => %{module: YayakaSocialGraph.MessageHandler},
}


import_config "../apps/*/config/config.exs"
