use Mix.Config

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
      "notification-types" => ~w(follow reply repost quote)
    }]
  }
}

https_token = %{
  name: "https-token",
  version: "0.1.0",
  parameters: %{
    "request-path" => "/api/ymp/https-token/request",
    "grant-path" => "/api/ymp/https-token/grant",
    "packet-path" => "/api/ymp/https-token/packet"
  }
}

if Mix.env == :test do
  config :ymp, :host_information, %{
    "ymp-version" => "0.1.0",
    "connection-protocols" => [https_token],
    "service_protocols" => [yayaka]
  }
end

config :ymp, HTTPSTokenConnection, https_token

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
  notification_types: notification_types

import_config "../apps/*/config/config.exs"
