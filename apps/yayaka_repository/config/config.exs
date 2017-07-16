use Mix.Config

string = %{"type" => "string"}
host = string

content_types = %{
  "yayaka" => %{
    "plaintext" => %{
      "type" => "object",
      "properties" => %{
        "label" => string,
        "text" => string},
      "required" => ["text"]}}}


config :yayaka_repository, :content_types, content_types

content = %{
  "oneOf" => Enum.map(content_types, fn {protocol, types} ->
    Enum.map(types, fn {type, body} ->
      %{
        "type" => "object",
        "properties" => %{
          "protocol" => %{"enum" => [protocol]},
          "type" => %{"enum" => [type]},
          "body" => body},
        "required" => ["protocol", "type", "body"]}
    end)
  end) |> List.flatten()
}

post = %{
  "type" => "object",
  "properties" => %{
    "title" => string,
    "contents" => %{
      "type" => "array",
      "items" => content}},
  "required" => ["contents"]}

config :yayaka_repository, :event_types, %{
  "yayaka" => %{
    "post" => post,
    "repost" => %{
      "type" => "object",
      "properties" => %{
        "repository-host" => string,
        "event-id" => string},
      "required" => ["repository-host", "event-id"]},
    "reply" => %{
      "type" => "object",
      "properties" => %{
        "repository-host" => string,
        "event-id" => string,
        "title" => string,
        "contents" => %{
          "type" => "array",
          "items" => content}},
      "required" => [
        "repository-host", "event-id", "contents"]},
    "quote" => %{
      "type" => "object",
      "properties" => %{
        "repository-host" => string,
        "event-id" => string,
        "title" => string,
        "contents" => %{
          "type" => "array",
          "items" => content}},
      "required" => [
        "repository-host", "event-id", "contents"]},
    "follow" => %{
      "type" => "object",
      "properties" => %{
        "social-graph-host" => string,
        "target-identity-host" => string,
        "target-user-id" => string,
        "target-social-graph-host" => string},
      "required" => [
        "social-graph-host",
        "target-identity-host",
        "target-user-id",
        "target-social-graph-host"]},
    "delete-post" => %{
      "type" => "object",
      "properties" => %{
        "event-id" => string},
      "required" => ["event-id"]},
    "update-post" => %{
      "type" => "object",
      "properties" => %{
        "event-id" => string,
        "body" => post},
      "required" => ["event-id", "body"]}
  }
}
