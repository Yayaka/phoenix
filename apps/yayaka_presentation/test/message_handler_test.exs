defmodule YayakaPresentation.MessageHandlerTest do
  use ExUnit.Case
  alias Yayaka.MessageHandler.Utils
  alias YayakaPresentation.TimelineSubscriptionRegistry
  alias YayakaPresentation.TimelineSubscription
  import YMP.TestMessageHandler, only: [request: 2, request: 3]

  @host YMP.get_host()
  @handler YayakaPresentation.MessageHandler

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
  end

  test "push-event" do
    now = DateTime.utc_now() |> DateTime.to_unix()
    user = %{host: "host1", id: "id1"}
    social_graph = %{host: "host2", service: :social_graph}
    subscription = %TimelineSubscription{
      id: "id2",
      user: user,
      social_graph: social_graph,
      expires: now + 1000
    } |> DB.Repo.insert!()
    task = Task.async(fn ->
      Registry.register(TimelineSubscriptionRegistry, subscription.id, :ok)
      assert_receive {:event, event}
      :ok
    end)
    payload = %{
      "subscription-id" => subscription.id,
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
    push_event =
      YMP.Message.new(@host,
                      "yayaka", "presentation", "push-event", payload,
                      "yayaka", "social-graph")
    {:ok, answer} = request(@handler, push_event)
    assert answer["payload"]["body"]
    assert :ok == Task.await(task)
  end
end
