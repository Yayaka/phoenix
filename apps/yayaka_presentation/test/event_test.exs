defmodule YayakaPresentation.EventTest do
  use ExUnit.Case
  import YMP.TestMessageHandler, only: [represent_remote_host: 1]
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
    represent_remote_host(repository_host)
    task = Task.async(fn ->
      YMP.TestMessageHandler.register("create-event", repository_host)
      receive do
        message ->
          assert message["payload"]["identity-host"] == user.host
          assert message["payload"]["user-id"] == user.id
          assert message["payload"]["protocol"] == event["protocol"]
          assert message["payload"]["type"] == event["type"]
          assert message["payload"]["body"] == event["body"]
          body = %{"event-id" => created_event_id}
          answer = Utils.new_answer(message, body)
          YMP.MessageGateway.push(answer)
      end
    end)
    assert {:ok, created_event_id} == Event.create(user, repository_host, event)
    assert :ok == Task.await(task)
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
    represent_remote_host(repository_host)
    task = Task.async(fn ->
      YMP.TestMessageHandler.register("fetch-event", repository_host)
      receive do
        message ->
          assert message["payload"]["event-id"] == event_id
          body = event
          answer = Utils.new_answer(message, body)
          YMP.MessageGateway.push(answer)
      end
    end)
    assert {:ok, event} == Event.fetch(repository_host, event_id)
    assert :ok == Task.await(task)
  end
end
