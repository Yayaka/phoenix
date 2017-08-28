defmodule YayakaRepository.MessageHandler do
  @behaviour Amorphos.MessageHandler

  alias YayakaIdentity.IdentityUser
  alias YayakaIdentity.UserAttribute
  alias YayakaIdentity.AuthorizedService
  alias YayakaRepository.Event
  alias Yayaka.MessageHandler.Utils
  import Ecto.Changeset
  import Ecto.Query
  alias Yayaka.YayakaUserCache
  alias Yayaka.YayakaUser
  require Logger

  def handle(%{"action" => "create-event"} = message) do
    %{"identity-host" => identity_host,
      "user-id" => user_id,
      "protocol" => protocol,
      "type" => type,
      "body" => body} = message["payload"]
    sender = Utils.get_sender(message)
    "presentation" = sender.service
    {:ok, yayaka_user} =
      YayakaUserCache.get_or_fetch(%{host: identity_host, id: user_id})
    true = YayakaUser.authorizes?(yayaka_user, sender)
    params = %{
      id: UUID.uuid4(),
      user: %{host: identity_host, id: user_id},
      protocol: protocol,
      type: type,
      body: body,
      sender: sender
    }
    changeset = Event.changeset(%Event{}, params)
    event = DB.Repo.insert!(changeset)
    reposiotry_subscriptions =
      YayakaUser.get_attribute(yayaka_user, "yayaka", "repository-subscriptions")
    reposiotry_subscriptions["value"]["subscriptions"]
    |> Enum.each(fn subscription ->
      %{"repository-host" => repository_host,
        "social-graph-host" => social_graph_host} = subscription
      if repository_host == Amorphos.get_host() do
        payload = %{
          "repository-host" => @host,
          "event-id" => event.id,
          "identity-host" => event.user.host,
          "user-id" => event.user.id,
          "protocol" => event.protocol,
          "type" => event.type,
          "body" => event.body,
          "sender-host" => event.sender.host,
          "created-at" => Utils.to_datetime(event.inserted_at)}
        message = Amorphos.Message.new(social_graph_host,
                                  "yayaka", "social-graph", "broadcast-event",
                                  payload, "yayaka", "repository")
        Amorphos.MessageGateway.request(message)
      end
    end)
    body = %{
      "event-id" => event.id
    }
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "fetch-event"} = message) do
    %{"event-id" => event_id} = message["payload"]
    query = from e in Event,
      where: e.id == ^event_id
    case DB.Repo.one(query) do
      nil ->
        payload = %{
          "status" => "not-found",
          "body" => %{}
        }
        answer = Amorphos.Message.new_answer(message, payload)
        Amorphos.MessageGateway.push(answer)
      event ->
        body = %{
          "identity-host" => event.user.host,
          "user-id" => event.user.id,
          "protocol" => event.protocol,
          "type" => event.type,
          "body" => event.body,
          "sender-host" => event.sender.host,
          "created-at" => Utils.to_datetime(event.inserted_at)}
        answer = Utils.new_answer(message, body)
        Amorphos.MessageGateway.push(answer)
    end
  end
end
