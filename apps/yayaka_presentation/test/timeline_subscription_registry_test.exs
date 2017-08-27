defmodule YayakaPresentation.TimelineSubscriptionRegistryTest do
  use ExUnit.Case
  alias YayakaPresentation.TimelineSubscriptionRegistry
  alias YayakaPresentation.TimelineSubscription
  import YMP.TestMessageHandler, only: [with_mocks: 1, mock: 3]
  alias Yayaka.MessageHandler.Utils
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
  end

  test "subscribe with an expired subscription" do
    now = DateTime.utc_now() |> DateTime.to_unix()
    expires = now - 1000 # expired
    user = %{host: "host1", id: "id1"}
    social_graph = %{host: "host2", service: :social_graph}
    %TimelineSubscription{
      id: "id1", user: user, social_graph: social_graph, expires: expires
    } |> DB.Repo.insert!()
    subscription_id = "subscription_id1"
    with_mocks do
      mock social_graph.host, "subscribe-timeline", fn message ->
        assert message["payload"]["expires"] > now
        assert message["payload"]["identity-host"] == user.host
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["limit"] == 0
        body = %{
          "subscription-id" => subscription_id,
          "expires" => now + 1000,
          "events" => []}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert {:ok, subscription, []} =
        TimelineSubscriptionRegistry.subscribe(social_graph.host, user)
      query = from s in TimelineSubscription,
        where: s.user == ^user,
        where: s.social_graph == ^social_graph,
        where: s.expires > ^now
      assert subscription == DB.Repo.one(query)
      assert subscription.id == subscription_id
      assert subscription.expires == now + 1000
      assert [{self(), :ok}] ==
        Registry.lookup(TimelineSubscriptionRegistry, subscription.id)
    end
  end

  test "subscribe with an available subscription" do
    expires = (DateTime.utc_now() |> DateTime.to_unix()) + 1000 # not expired
    user = %{host: "host1", id: "id1"}
    social_graph = %{host: "host2", service: :social_graph}
    %TimelineSubscription{
      id: "id1", user: user, social_graph: social_graph, expires: expires
    } |> DB.Repo.insert!()
    subscription = DB.Repo.get(TimelineSubscription, "id1")
    assert {:ok, subscription, []} ==
      TimelineSubscriptionRegistry.subscribe(social_graph.host, user)
    assert [{self(), :ok}] ==
      Registry.lookup(TimelineSubscriptionRegistry, subscription.id)
  end

  test "unsubscribe" do
    now = DateTime.utc_now() |> DateTime.to_unix()
    expires = (DateTime.utc_now() |> DateTime.to_unix()) + 1000
    user = %{host: "host1", id: "id1"}
    social_graph = %{host: "host2", service: :social_graph}
    subscription_id = "id1"
    %TimelineSubscription{
      id: subscription_id, user: user, social_graph: social_graph, expires: expires
    } |> DB.Repo.insert!()
    with_mocks do
      mock social_graph.host, "unsubscribe-timeline", fn message ->
        assert message["payload"]["subscription-id"] == subscription_id
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert :ok ==
        TimelineSubscriptionRegistry.unsubscribe(social_graph.host, user)
      query = from s in TimelineSubscription,
        where: s.user == ^user,
        where: s.social_graph == ^social_graph,
        where: s.expires > ^now
      assert 0 == DB.Repo.aggregate(query, :count, :id)
    end
  end

  test "extend" do
    now = DateTime.utc_now() |> DateTime.to_unix()
    expires = (DateTime.utc_now() |> DateTime.to_unix()) + 100
    user = %{host: "host1", id: "id1"}
    social_graph = %{host: "host2", service: :social_graph}
    subscription_id = "id1"
    %TimelineSubscription{
      id: subscription_id, user: user, social_graph: social_graph, expires: expires
    } |> DB.Repo.insert!()
    with_mocks do
      mock social_graph.host, "extend-timeline-subscription", fn message ->
        assert message["payload"]["subscription-id"] == subscription_id
        assert message["payload"]["expires"] > now
        body = %{"expires" => message["payload"]["expires"]}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert :ok ==
        TimelineSubscriptionRegistry.extend(social_graph.host, user)
      query = from s in TimelineSubscription,
        where: s.user == ^user,
        where: s.social_graph == ^social_graph,
        where: s.expires > ^now
      assert DB.Repo.one!(query).expires > expires
    end
  end

  test "push_event" do
    now = DateTime.utc_now() |> DateTime.to_unix()
    user = %{host: "host1", id: "id1"}
    social_graph = %{host: "host2", service: :social_graph}
    expired = %TimelineSubscription{
      id: "id1",
      user: user,
      social_graph: social_graph,
      expires: now - 1000
    } |> DB.Repo.insert!()
    available = %TimelineSubscription{
      id: "id2",
      user: user,
      social_graph: social_graph,
      expires: now + 1000
    } |> DB.Repo.insert!()
    event = %{
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
      }}
    task1 = Task.async(fn ->
      Registry.register(TimelineSubscriptionRegistry, expired.id, :ok)
      refute_receive {:event, event}
      :ok
    end)
    task2 = Task.async(fn ->
      Registry.register(TimelineSubscriptionRegistry, available.id, :ok)
      assert_receive {:event, event}
      :ok
    end)
    assert :error ==
      TimelineSubscriptionRegistry.push_event(expired.id, event)
    assert :ok ==
      TimelineSubscriptionRegistry.push_event(available.id, event)
    assert :ok == Task.await(task1)
    assert :ok == Task.await(task2)
  end
end
