defmodule Web.TimelineChannelTest do
  use Web.ChannelCase
  alias Web.TimelineChannel
  import YMP.TestMessageHandler, only: [with_mocks: 1, mock: 3]
  alias Yayaka.MessageHandler.Utils

  @assigns %{
    social_graph_host: "host1",
    identity_host: "host2",
    user_id: "id1"}
  @subscription_id "id1"

  defp create_socket() do
    now = DateTime.utc_now() |> DateTime.to_unix()
    with_mocks do
      mock @assigns.social_graph_host, "subscribe-timeline", fn message ->
        assert message["payload"]["identity-host"] == @assigns.identity_host
        assert message["payload"]["user-id"] == @assigns.user_id
        body = %{
          "subscription-id" => @subscription_id,
          "expires" => now + 1000,
          "events" => []}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      {:ok, _, socket} =
        socket(nil, @assigns)
        |> subscribe_and_join(TimelineChannel, "timeline")
      socket
    end
  end

  test "create event" do
    event = %{
      "protocol" => "text",
      "type" => "post",
      "body" => %{
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}]
      }}
    repository_host = "host1"
    created_event_id = "created-event-id"
    with_mocks do
      mock repository_host, "create-event", fn message ->
        assert message["payload"]["identity-host"] == @assigns.identity_host
        assert message["payload"]["user-id"] == @assigns.user_id
        assert message["payload"]["protocol"] == event["protocol"]
        assert message["payload"]["type"] == event["type"]
        assert message["payload"]["body"] == event["body"]
        body = %{"event-id" => created_event_id}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      socket = create_socket()
      message = %{
        "repository_host" => repository_host,
        "event" => event
      }
      ref = push socket, "create_event", message
      assert_reply ref, :ok, %{event_id: created_event_id}
    end
  end

  test "push event" do
    socket = create_socket()
    event = %{
      "subscription-id" => @subscription_id,
      "repository-host" => "host1",
      "event-id" => "id1",
      "identity-host" => "host1",
      "user-id" => "id1",
      "protocol" => "text",
      "type" => "post",
      "body" => %{
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}
        ]
      },
      "sender-host" => "host2",
      "created-at" => DateTime.utc_now() |> DateTime.to_iso8601()}
    TimelineChannel.handle_info({:event, event}, socket)
    assert_push "push_event", %{event: ^event}
  end
end
