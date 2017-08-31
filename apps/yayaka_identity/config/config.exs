use Mix.Config

string = %{"type" => "string"}
host = %{"type" => "string"}
service = %{
  "type" => "string",
  "enum" => ["presentation",
           "identity",
           "repository",
           "social-graph",
           "notification"]}

config :yayaka_identity, :user_attribute_types, %{
  "yayaka" => %{
    "service-labels" => %{
      "type" => "object",
      "properties" => %{
        "labels" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "host" => host,
              "service" => service,
              "label" => string},
            "additionalProperties" => false,
            "required" => ["host", "service", "label"]}}},
      "additionalProperties" => false,
      "required" => ["labels"]},
    "subscriber-hosts" => %{
      "type" => "object",
      "properties" => %{
        "hosts" => %{
          "type" => "array",
          "items" => host}},
      "additionalProperties" => false,
      "required" => ["hosts"]},
    "publisher-hosts" => %{
      "type" => "object",
      "properties" => %{
        "hosts" => %{
          "type" => "array",
          "items" => host}},
      "additionalProperties" => false,
      "required" => ["hosts"]},
    "primary-publisher-host" => %{
      "type" => "object",
      "properties" => %{"host" => string},
      "additionalProperties" => false,
      "required" => ["host"]},
    "primary-repository-host" => %{
      "type" => "object",
      "properties" => %{"host" => string},
      "additionalProperties" => false,
      "required" => ["host"]},
    "primary-notification-host" => %{
      "type" => "object",
      "properties" => %{"host" => string},
      "additionalProperties" => false,
      "required" => ["host"]},
    "repository-subscriptions" => %{
      "type" => "object",
      "properties" => %{
        "subscriptions" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "repository-host" => host,
              "social-graph-host" => host},
            "additionalProperties" => false,
            "required" => ["repository-host", "social-graph-host"]}}},
      "additionalProperties" => false,
      "required" => ["subscriptions"]},
    "biography" => %{
      "type" => "object",
      "properties" => %{"text" => string},
      "additionalProperties" => false,
      "required" => ["text"]},
    "links" => %{
      "type" => "object",
      "properties" => %{
        "urls" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "label" => string,
              "url" => string},
            "additionalProperties" => false,
            "required" => ["label", "url"]}}},
      "additionalProperties" => false,
      "required" => ["urls"]},
    "icon" => %{
      "type" => "object",
      "properties" => %{"url" => string},
      "additionalProperties" => false,
      "required" => ["url"]},
    "name" => %{
      "type" => "object",
      "properties" => %{"text" => string},
      "additionalProperties" => false,
      "required" => ["text"]},
  }
}

config :yayaka_identity, :user_attribute_default_values, %{
  "yayaka" => %{
    "service-labels" => %{
      "labels" => []},
    "subscriber-hosts" => %{
      "hosts" => []},
    "publisher-hosts" => %{
      "hosts" => []},
    "primary-publisher-host" => %{
      "host" => nil},
    "primary-repository-host" => %{
      "host" => nil},
    "primary-notification-host" => %{
      "host" => nil},
    "repository-subscriptions" => %{
      "subscriptions" => []},
    "biography" => %{
      "text" => nil},
    "links" => %{
      "urls" => []},
    "icon" => %{
      "url" => nil},
    "name" => %{
      "text" => nil},
  }
}
