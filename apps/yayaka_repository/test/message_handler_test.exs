defmodule YayakaRepository.MessageHandlerTest do
  use ExUnit.Case
  alias YayakaIdentity.IdentityUser
  alias YayakaIdentity.UserAttribute
  alias YayakaIdentity.AuthorizedService
  alias YayakaRepository.Event
  alias Yayaka.MessageHandler.Utils
  import Ecto.Query
  import YMP.TestMessageHandler, only: [request: 2, request: 3]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
    Cachex.clear(:yayaka_user)
    Cachex.clear(:yayaka_user_name)
    :ok
  end

  @host YMP.get_host()
  @handler YayakaRepository.MessageHandler

  def create_message(action, payload, sender_service \\ "presentation") do
    YMP.Message.new(@host,
                    "yayaka", "repository", action, payload,
                    "yayaka", sender_service)
  end

  def authorize(user) do
    authorization = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: @host, service: :presentation},
      sender: %{host: @host, service: :presentation}
    }
    DB.Repo.insert!(authorization)
  end

  def revoke_authorization(authorization) do
    DB.Repo.delete!(authorization)
  end

  test "create-event" do
    pid = self()
    identity_host = @host
    social_graph_host = @host
    user = %IdentityUser{
      id: "aaa",
      name: "user1",
      user_attributes: [
        %UserAttribute{
          protocol: "yayaka",
          key: "repository-subscriptions",
          value: %{
            "subscriptions" => [
              %{"repository-host" => @host,
                "social-graph-host" => social_graph_host}]},
          sender: %{host: "host1", service: :presentation}}],
      sender: %{host: @host, service: :presentation}}
    DB.Repo.insert!(user)
    authorization = authorize(user)

    spawn_link(fn ->
      YMP.TestMessageHandler.register("fetch-user")
      receive do
        message ->
          YayakaIdentity.MessageHandler.handle(message)
      end
    end)
    spawn_link(fn ->
      YMP.TestMessageHandler.register("broadcast-event")
      receive do
        message ->
          send pid, message
          answer = Utils.new_answer(message, %{})
          YMP.MessageGateway.push(answer)
      end
    end)
    payload = %{
      "identity-host" => identity_host,
      "user-id" => user.id,
      "protocol" => "yayaka",
      "type" => "post",
      "body" => %{
        "contents" => [
          %{
            "protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "text1"}
          }]}}
    message = create_message("create-event", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    receive do
      pushed ->
        payload = pushed["payload"]
        assert pushed["host"] == social_graph_host
        assert pushed["service"] == "social-graph"
        assert payload["repository-host"] == body["repository-host"]
        assert payload["event-id"] == body["event-id"]
        assert payload["identity-host"] == identity_host
        assert payload["user-id"] == user.id
        assert payload["protocol"] == payload["protocol"]
        assert payload["type"] == payload["type"]
        assert payload["body"] == payload["body"]
        assert payload["sender-host"] == @host
        created = NaiveDateTime.from_iso8601!(payload["created-at"])
                  |> DateTime.from_naive!("Etc/UTC")
                  |> DateTime.to_unix
        assert (DateTime.utc_now() |> DateTime.to_unix()) - created < 1000
    after
      500 -> flunk "timeout"
    end
  end

  test "fetch-event" do
    event = %Event{
      id: "aaa",
      user: %{host: "host1", id: "user1"},
      protocol: "yayaka",
      type: "post",
      body: %{
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "text1"}}]},
      sender: %{host: "host1", service: "presentation"}
    }
    event = DB.Repo.insert!(event)
    payload = %{
      "event-id" => "aaa",
    }
    message = create_message("fetch-event", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    assert body["identity-host"] == event.user.host
    assert body["user-id"] == event.user.id
    assert body["protocol"] == event.protocol
    assert body["type"] == event.type
    assert body["body"] == event.body
    assert body["sender-host"] == event.sender.host
    naive = body["created-at"] |> NaiveDateTime.from_iso8601!
    assert naive == event.inserted_at
  end
end
