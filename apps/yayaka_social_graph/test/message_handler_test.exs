defmodule YayakaSocialGraph.MessageHandlerTest do
  use ExUnit.Case
  alias YayakaIdentity.IdentityUser
  alias YayakaIdentity.AuthorizedService
  alias YayakaSocialGraph.Subscription
  alias YayakaSocialGraph.Subscriber
  alias YayakaSocialGraph.Event
  alias YayakaSocialGraph.TimelineEvent
  alias YayakaSocialGraph.TimelineSubscriber
  alias Yayaka.MessageHandler.Utils
  import Ecto.Query
  import YMP.TestMessageHandler, only: [request: 2, request: 3,
                                        represent_remote_host: 1,
                                        with_mocks: 1, mock: 3]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
    Cachex.clear(:yayaka_user)
    Cachex.clear(:yayaka_user_name)
    :ok
  end

  @host YMP.get_host()
  @handler YayakaSocialGraph.MessageHandler

  def create_message(action, payload, sender_service \\ "presentation") do
    YMP.Message.new(@host,
                    "yayaka", "social-graph", action, payload,
                    "yayaka", sender_service)
  end

  def authorize(user, service \\ :presentation) do
    authorization = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: @host, service: service},
      sender: %{host: @host, service: :presentation}
    }
    DB.Repo.insert!(authorization)
  end

  def revoke_authorization(authorization) do
    DB.Repo.delete!(authorization)
  end


  test "subscribe" do
    user = %IdentityUser{
      id: "aaa",
      name: "user1",
      sender: %{host: @host, service: :presentation}}
    user2 = %IdentityUser{
      id: "bbb",
      name: "user2",
      sender: %{host: @host, service: :presentation}}
    DB.Repo.insert!(user)
    authorization = authorize(user, :presentation)
    with_mocks do
      mock "host1", "fetch-user", fn message ->
        YayakaIdentity.MessageHandler.handle(message)
      end
      mock "host3", "add-subscriber", fn message ->
        %{"subscriber-identity-host" => host1,
          "subscriber-user-id" => id1,
          "publisher-identity-host" => host2,
          "publisher-user-id" => id2} = message["payload"]
        assert host1 == "host1"
        assert host2 == "host2"
        assert id1 == user.id
        assert id2 == user2.id
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      payload = %{
        "subscriber-identity-host" => "host1",
        "subscriber-user-id" => user.id,
        "publisher-identity-host" => "host2",
        "publisher-user-id" => user2.id,
        "publisher-social-graph-host" => "host3"
      }
      message = create_message("subscribe", payload)
      {:ok, answer} = request(@handler, message)
      assert answer["payload"]["body"] == %{}
      query = from s in Subscription,
        where: s.user == ^%{host: "host1", id: user.id},
        where: s.target_user == ^%{host: "host2", id: user2.id},
        where: s.social_graph == ^%{host: "host3", service: :social_graph}
      assert DB.Repo.aggregate(query, :count, :id) == 1
    end
  end

  test "unsubscribe" do
    user = %IdentityUser{
      id: "aaa",
      name: "user1",
      sender: %{host: @host, service: :presentation}}
    user2 = %IdentityUser{
      id: "bbb",
      name: "user2",
      sender: %{host: @host, service: :presentation}}
    DB.Repo.insert!(user)
    authorization = authorize(user, :presentation)
    with_mocks do
      mock "host1", "fetch-user", fn message ->
        YayakaIdentity.MessageHandler.handle(message)
      end
      mock "host3", "remove-subscriber", fn message ->
        %{"subscriber-identity-host" => host1,
          "subscriber-user-id" => id1,
          "publisher-identity-host" => host2,
          "publisher-user-id" => id2} = message["payload"]
        assert host1 == "host1"
        assert host2 == "host2"
        assert id1 == user.id
        assert id2 == user2.id
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      subscription = %Subscription{
        user: %{host: "host1", id: user.id},
        target_user: %{host: "host2", id: user2.id},
        social_graph: %{host: "host3", service: :social_graph},
        sender: %{host: @host, service: :presentation}}
      subscription = DB.Repo.insert!(subscription)
      payload = %{
        "subscriber-identity-host" => "host1",
        "subscriber-user-id" => user.id,
        "publisher-identity-host" => "host2",
        "publisher-user-id" => user2.id,
        "publisher-social-graph-host" => "host3"
      }
      message = create_message("unsubscribe", payload)
      {:ok, answer} = request(@handler, message)
      assert answer["payload"]["body"] == %{}
      assert nil == DB.Repo.get(Subscription, subscription.id)
    end
  end

  test "add-subscriber" do
    user = %IdentityUser{
      id: "aaa",
      name: "user1",
      sender: %{host: @host, service: :presentation}}
    user2 = %IdentityUser{
      id: "bbb",
      name: "user2",
      sender: %{host: @host, service: :presentation}}
    DB.Repo.insert!(user)
    authorization = authorize(user, :social_graph)
    represent_remote_host("host1")
    with_mocks do
      mock "host1", "fetch-user", fn message ->
        YayakaIdentity.MessageHandler.handle(message)
      end
      payload = %{
        "subscriber-identity-host" => "host1",
        "subscriber-user-id" => user.id,
        "publisher-identity-host" => "host2",
        "publisher-user-id" => user2.id,
      }
      message = create_message("add-subscriber", payload, "social-graph")
      {:ok, answer} = request(@handler, message)
      assert answer["payload"]["body"] == %{}
      query = from s in Subscriber,
        where: s.user == ^%{host: "host1", id: user.id},
        where: s.target_user == ^%{host: "host2", id: user2.id},
        where: s.social_graph == ^%{host: @host, service: :social_graph}
      assert DB.Repo.aggregate(query, :count, :id) == 1
    end
  end

  test "remove-subscriber" do
    user = %IdentityUser{
      id: "aaa",
      name: "user1",
      sender: %{host: @host, service: :presentation}}
    user2 = %IdentityUser{
      id: "bbb",
      name: "user2",
      sender: %{host: @host, service: :presentation}}
    DB.Repo.insert!(user)
    authorization = authorize(user, :social_graph)
    represent_remote_host("host1")
    with_mocks do
      mock "host1", "fetch-user", fn message ->
        YayakaIdentity.MessageHandler.handle(message)
      end
      subscriber = %Subscriber{
        user: %{host: "host1", id: user.id},
        target_user: %{host: "host2", id: user2.id},
        social_graph: %{host: @host, service: :social_graph},
        sender: %{host: @host, service: :social_graph}}
      subscriber = DB.Repo.insert!(subscriber)
      payload = %{
        "subscriber-identity-host" => "host1",
        "subscriber-user-id" => user.id,
        "publisher-identity-host" => "host2",
        "publisher-user-id" => user2.id,
      }
      message = create_message("remove-subscriber", payload, "social-graph")
      {:ok, answer} = request(@handler, message)
      assert answer["payload"]["body"] == %{}
      query = from s in Subscriber,
        where: s.user == ^%{host: "host1", id: user.id},
        where: s.target_user == ^%{host: "host2", id: user2.id},
        where: s.social_graph == ^%{host: @host, service: :social_graph}
      assert nil == DB.Repo.get(Subscriber, subscriber.id)
    end
  end

  test "fetch-user-relations" do
    user1 = %{host: "host1", id: "id1"}
    user2 = %{host: "host1", id: "id2"}
    user3 = %{host: "host1", id: "id3"}
    user4 = %{host: "host1", id: "id4"}
    social_graph = %{host: "host2", service: :social_graph}
    subscription1 = %Subscription{
      user: user1,
      target_user: user2,
      social_graph: social_graph,
      sender: %{host: @host, service: :presentation}}
    subscription1 = DB.Repo.insert!(subscription1)
    subscription2 = %Subscription{
      user: user1,
      target_user: user3,
      social_graph: social_graph,
      sender: %{host: @host, service: :presentation}}
    subscription2 = DB.Repo.insert!(subscription2)
    subscriber1 = %Subscriber{
      user: user3,
      target_user: user1,
      social_graph: social_graph,
      sender: social_graph}
    subscriber1 = DB.Repo.insert!(subscriber1)
    subscriber2 = %Subscriber{
      user: user4,
      target_user: user1,
      social_graph: social_graph,
      sender: social_graph}
    subscriber2 = DB.Repo.insert!(subscriber2)
    payload = %{
      "identity-host" => user1.host,
      "user-id" => user1.id}
    message = create_message("fetch-user-relations", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    subscriptions = body["subscriptions"]
    subscribers = body["subscribers"]
    assert length(subscriptions) == 2
    assert length(subscribers) == 2
    assert %{"identity-host" => user2.host, "user-id" => user2.id,
      "social-graph-host" => social_graph.host} in subscriptions
    assert %{"identity-host" => user3.host, "user-id" => user3.id,
      "social-graph-host" => social_graph.host} in subscriptions
    assert %{"identity-host" => user3.host, "user-id" => user3.id,
      "social-graph-host" => social_graph.host} in subscribers
    assert %{"identity-host" => user4.host, "user-id" => user4.id,
      "social-graph-host" => social_graph.host} in subscribers
  end

  test "fetch-timeline" do
    user = %{host: "host1", id: "id1"}
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
    event1 = %Event{
      repository: %{host: "host1", service: :repository},
      event_id: "id1",
      event: event,
      sender: %{host: @host, service: :social_graph}} |> DB.Repo.insert!()
    event2 = %Event{
      repository: %{host: "host1", service: :repository},
      event_id: "id2",
      event: event,
      sender: %{host: @host, service: :social_graph}} |> DB.Repo.insert!()
    timeline_event1 = %TimelineEvent{
      user: user, event_id: event1.id
    } |> DB.Repo.insert!()
    timeline_event2 = %TimelineEvent{
      user: user, event_id: event2.id
    } |> DB.Repo.insert!()
    timeline_event3 = %TimelineEvent{
      user: user, event_id: event2.id
    } |> DB.Repo.insert!()
    payload = %{
      "identity-host" => user.host,
      "user-id" => user.id}
    message = create_message("fetch-timeline", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    events = body["events"]
    assert length(events) == 3
    assert %{"repository-host" => event1.repository.host,
      "event-id" => event1.event_id,
      "identity-host" => event1.event["identity-host"],
      "user-id" => event1.event["user-id"],
      "protocol" => event1.event["protocol"],
      "type" => event1.event["type"],
      "body" => event1.event["body"],
      "sender-host" => event1.sender.host,
      "created-at" => Utils.to_datetime(timeline_event1.inserted_at)} == Enum.at(events, 2)
    assert %{"repository-host" => event2.repository.host,
      "event-id" => event2.event_id,
      "identity-host" => event2.event["identity-host"],
      "user-id" => event2.event["user-id"],
      "protocol" => event2.event["protocol"],
      "type" => event2.event["type"],
      "body" => event2.event["body"],
      "sender-host" => event2.sender.host,
      "created-at" => Utils.to_datetime(timeline_event2.inserted_at)} == Enum.at(events, 1)
    assert %{"repository-host" => event2.repository.host,
      "event-id" => event2.event_id,
      "identity-host" => event2.event["identity-host"],
      "user-id" => event2.event["user-id"],
      "protocol" => event2.event["protocol"],
      "type" => event2.event["type"],
      "body" => event2.event["body"],
      "sender-host" => event2.sender.host,
      "created-at" => Utils.to_datetime(timeline_event3.inserted_at)} == Enum.at(events, 0)
  end

  test "subscribe-timeline" do
    user = %{host: "host1", id: "id1"}
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
    event1 = %Event{
      repository: %{host: "host1", service: :repository},
      event_id: "id1",
      event: event,
      sender: %{host: @host, service: :social_graph}} |> DB.Repo.insert!()
    timeline_event1 = %TimelineEvent{
      user: user, event_id: event1.id
    } |> DB.Repo.insert!()
    payload = %{
      "expires" => (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
      "identity-host" => user.host,
      "user-id" => user.id}
    message = create_message("subscribe-timeline", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    id = body["subscription-id"]
    events = body["events"]
    assert body["expires"] == payload["expires"]
    assert length(events) == 1
    assert %{"repository-host" => event1.repository.host,
      "event-id" => event1.event_id,
      "identity-host" => event1.event["identity-host"],
      "user-id" => event1.event["user-id"],
      "protocol" => event1.event["protocol"],
      "type" => event1.event["type"],
      "body" => event1.event["body"],
      "sender-host" => event1.sender.host,
      "created-at" => Utils.to_datetime(timeline_event1.inserted_at)} == Enum.at(events, 0)
    query = from ts in TimelineSubscriber,
      where: ts.id == ^id,
      where: ts.user == ^%{host: user.host, id: user.id},
      where: ts.presentation == ^%{host: @host, service: :presentation}
    assert DB.Repo.aggregate(query, :count, :id) == 1
  end

  test "unsubscribe-timeline" do
    subscriber = %TimelineSubscriber{
      id: UUID.uuid4(),
      user: %{host: "host1", id: "id1"},
      presentation: %{host: @host, service: :presentation},
      expires: (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
      sender: %{host: @host, service: :presentation}}
    |> DB.Repo.insert!()
    payload = %{"subscription-id" => subscriber.id}
    message = create_message("unsubscribe-timeline", payload)
    {:ok, answer} = request(@handler, message)
    assert answer["payload"]["body"] == %{}
    query = from ts in TimelineSubscriber,
      where: ts.id == ^subscriber.id
    assert DB.Repo.aggregate(query, :count, :id) == 0
  end

  test "extend-timeline" do
    subscriber = %TimelineSubscriber{
      id: UUID.uuid4(),
      user: %{host: "host1", id: "id1"},
      presentation: %{host: @host, service: :presentation},
      expires: (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
      sender: %{host: @host, service: :presentation}}
    |> DB.Repo.insert!()
    new_expires = subscriber.expires + 1000
    payload = %{"subscription-id" => subscriber.id, "expires" => new_expires}
    message = create_message("extend-timeline-subscription", payload)
    {:ok, answer} = request(@handler, message)
    assert answer["payload"]["body"] == %{"expires" => new_expires}
    query = from ts in TimelineSubscriber,
      where: ts.id == ^subscriber.id
    subscriber = DB.Repo.one!(query)
    assert subscriber.expires == new_expires
  end

  test "broadcast-event from repository" do
    user1 = %{host: @host, id: "id1"}
    user2 = %{host: @host, id: "id2"}
    user = %IdentityUser{
      id: user1.id,
      name: "user1",
      sender: %{host: @host, service: :presentation}}
    DB.Repo.insert!(user)
    authorization = authorize(user, :repository)
    subscriber1 = %Subscriber{
      user: user1,
      target_user: user1,
      social_graph: %{host: @host, service: :social_graph},
      sender: %{host: @host, service: :social_graph}} |> DB.Repo.insert!()
    subscriber2 = %Subscriber{
      user: user2,
      target_user: user1,
      social_graph: %{host: "host1", service: :social_graph},
      sender: %{host: @host, service: :social_graph}} |> DB.Repo.insert!()
    event = %{
      "repository-host" => @host,
      "event-id" => "event1",
      "identity-host" => user1.host,
      "user-id" => user1.id,
      "protocol" => "yayaka",
      "type" => "post",
      "body" => %{
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}
        ]},
      "sender-host" => @host,
      "created-at" => DateTime.utc_now() |> DateTime.to_iso8601()}
    with_mocks do
      mock @host, "fetch-user", fn message ->
        YayakaIdentity.MessageHandler.handle(message)
      end
      mock "host1", "broadcast-event", fn message ->
        assert message["payload"] == event
      end
      mock @host, "broadcast-event", fn message ->
        # Ignore the requested message
      end
      mock @host, "broadcast-event", fn message ->
        assert message["payload"] == event
      end
      payload = event
      message = create_message("broadcast-event", payload, "repository")
      {:ok, answer} = request(@handler, message)
      assert = answer["payload"]["body"] == %{}
    end
  end

  test "broadcast-event from social-graph" do
    user1 = %{host: @host, id: "id1"}
    user2 = %{host: @host, id: "id2"}
    user = %IdentityUser{
      id: user1.id,
      name: "user1",
      sender: %{host: @host, service: :presentation}}
    DB.Repo.insert!(user)
    authorization = authorize(user, :social_graph)
    subscriber1 = %Subscription{
      user: user1,
      target_user: user1,
      social_graph: %{host: @host, service: :social_graph},
      sender: %{host: @host, service: :social_graph}} |> DB.Repo.insert!()
    subscriber2 = %Subscription{
      user: user2,
      target_user: user1,
      social_graph: %{host: @host, service: :social_graph},
      sender: %{host: @host, service: :social_graph}} |> DB.Repo.insert!()
    timeline_subscriber = %TimelineSubscriber{
      id: UUID.uuid4(),
      user: user2,
      presentation: %{host: "host1", service: :presentation},
      expires: (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
      sender: %{host: "host1", service: :presentation}}
    |> DB.Repo.insert!()
    event = %{
      "repository-host" => @host,
      "event-id" => "event1",
      "identity-host" => user1.host,
      "user-id" => user1.id,
      "protocol" => "yayaka",
      "type" => "post",
      "body" => %{
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}
        ]},
      "sender-host" => @host,
      "created-at" => DateTime.utc_now() |> DateTime.to_iso8601()}
    spawn_link(fn ->
      YMP.TestMessageHandler.register("fetch-user")
      receive do
        message ->
          YayakaIdentity.MessageHandler.handle(message)
      end
    end)
    represent_remote_host("host1")
    task = Task.async(fn ->
      YMP.TestMessageHandler.register("push-event", "host1")
      receive do
        message ->
          assert message["service"] == "presentation"
          assert message["payload"] == Map.put(event,
                                               "subscription-id",
                                               timeline_subscriber.id)
      end
    end)
    payload = event
    message = create_message("broadcast-event", payload, "social-graph")
    {:ok, answer} = request(@handler, message)
    assert = answer["payload"]["body"] == %{}
    Task.await(task, 50)
  end
end
