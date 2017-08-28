defmodule YayakaPresentation.Event do
  @spec create(Yayaka.User.t, String.t, map) :: {:ok, String.t} | :error
  def create(user, repository_host, event) do
    payload = %{
      "identity-host" => user.host,
      "user-id" => user.id,
      "protocol" => event["protocol"],
      "type" => event["type"],
      "body" => event["body"]}
    message = Amorphos.Message.new(repository_host,
                              "yayaka", "repository", "create-event",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"event-id" => event_id} = answer["payload"]["body"]
        {:ok, event_id}
      _ ->
        :error
    end
  end

  @spec fetch(String.t, String.t) :: {:ok, map} | :error
  def fetch(repository_host, event_id) do
    payload = %{"event-id" => event_id}
    message = Amorphos.Message.new(repository_host,
                              "yayaka", "repository", "fetch-event",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        {:ok, answer["payload"]["body"]}
      _ ->
        :error
    end
  end
end
