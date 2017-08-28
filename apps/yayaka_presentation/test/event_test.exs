defmodule YayakaPresentation.EventTest do
  use ExUnit.Case
  import Amorphos.TestMessageHandler, only: [with_mocks: 1, mock: 3]
  alias Yayaka.MessageHandler.Utils
  alias YayakaPresentation.Event

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
  end

  test "create" do
    user = %{host: "host1", id: "id1"}
    repository_host = "host2"
    event = %{
      "protocol" => "text",
      "type" => "post",
      "body" => %{
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}]
      }}
    created_event_id = "created-event-id"
    with_mocks do
      mock repository_host, "create-event", fn message ->
        assert message["payload"]["identity-host"] == user.host
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["protocol"] == event["protocol"]
        assert message["payload"]["type"] == event["type"]
        assert message["payload"]["body"] == event["body"]
        body = %{"event-id" => created_event_id}
        answer = Utils.new_answer(message, body)
        Amorphos.MessageGateway.push(answer)
      end
      assert {:ok, created_event_id} == Event.create(user, repository_host, event)
    end
  end

  test "fetch" do
    repository_host = "host1"
    event = %{
      "identity-host" => "host2",
      "user-id" => "user1",
      "protocol" => "text",
      "type" => "post",
      "body" => %{
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}]},
      "sender-host" => "host3",
      "created-at" => DateTime.utc_now() |> DateTime.to_iso8601()}
    event_id = "id1"
    with_mocks do
      mock repository_host, "fetch-event", fn message ->
        assert message["payload"]["event-id"] == event_id
        body = event
        answer = Utils.new_answer(message, body)
        Amorphos.MessageGateway.push(answer)
      end
      assert {:ok, event} == Event.fetch(repository_host, event_id)
    end
  end
end
