defmodule YayakaSocialGraph.MessageHandler do
  @behaviour YMP.MessageHandler

  alias YayakaIdentity.IdentityUser
  alias YayakaIdentity.UserAttribute
  alias YayakaIdentity.AuthorizedService
  alias YayakaSocialGraph.Subscription
  alias YayakaSocialGraph.Subscriber
  alias YayakaSocialGraph.Event
  alias YayakaSocialGraph.TimelineEvent
  alias YayakaSocialGraph.TimelineSubscriber
  alias Yayaka.MessageHandler.Utils
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  @max_timeline_subscription_length Application.get_env(:yayaka, :max_timeline_subscription_length)

  def handle(%{"action" => "subscribe"} = message) do
    %{"subscriber-identity-host" => subscriber_identity_host,
      "subscriber-user-id" => subscriber_user_id,
      "publisher-identity-host" => publisher_identity_host,
      "publisher-user-id" => publisher_user_id,
      "publisher-social-graph-host" => publisher_social_graph_host }
    = message["payload"]
    sender = Utils.get_sender(message)
    "presentation" = sender.service
    user_info = Utils.fetch_user(subscriber_identity_host,
                                 subscriber_user_id,
                                 "social-graph")
    true = Utils.is_authorized(user_info, sender)
    subscriber = %{
      host: subscriber_identity_host,
      id: subscriber_user_id}
    publisher = %{
      host: publisher_identity_host,
      id: publisher_user_id}
    social_graph = %{
      host: publisher_social_graph_host,
      service: :social_graph}
    query = from s in Subscription,
      where: s.user == ^subscriber,
      where: s.target_user == ^publisher,
      where: s.social_graph == ^social_graph
    0 = DB.Repo.aggregate(query, :count, :id)
    payload = %{
      "subscriber-identity-host" => subscriber.host,
      "subscriber-user-id" => subscriber.id,
      "publisher-identity-host" => publisher.host,
      "publisher-user-id" => publisher.id}
    add_subscriber = YMP.Message.new(publisher_social_graph_host,
                              "yayaka", "social-graph", "add-subscriber",
                              payload, "yayaka", "social-graph")
    {:ok, answer} = YMP.MessageGateway.request(add_subscriber)
    if answer["payload"]["body"] == %{} do
      params = %{
        user: subscriber,
        target_user: publisher,
        social_graph: social_graph,
        sender: sender}
      changeset = Subscription.changeset(%Subscription{}, params)
      DB.Repo.insert!(changeset)
      body = %{}
      answer = Utils.new_answer(message, body)
      YMP.MessageGateway.push(answer)
    end
  end

  def handle(%{"action" => "unsubscribe"} = message) do
    %{"subscriber-identity-host" => subscriber_identity_host,
      "subscriber-user-id" => subscriber_user_id,
      "publisher-identity-host" => publisher_identity_host,
      "publisher-user-id" => publisher_user_id,
      "publisher-social-graph-host" => publisher_social_graph_host}
    = message["payload"]
    sender = Utils.get_sender(message)
    "presentation" = sender.service
    user_info = Utils.fetch_user(subscriber_identity_host,
                                 subscriber_user_id,
                                 "social-graph")
    true = Utils.is_authorized(user_info, sender)
    subscriber = %{
      host: subscriber_identity_host,
      id: subscriber_user_id}
    publisher = %{
      host: publisher_identity_host,
      id: publisher_user_id}
    social_graph = %{
      host: publisher_social_graph_host,
      service: :social_graph}
    query = from s in Subscription,
      where: s.user == ^subscriber,
      where: s.target_user == ^publisher,
      where: s.social_graph == ^social_graph
    subscription = DB.Repo.one!(query)
    payload = %{
      "subscriber-identity-host" => subscriber.host,
      "subscriber-user-id" => subscriber.id,
      "publisher-identity-host" => publisher.host,
      "publisher-user-id" => publisher.id}
    remove_subscriber = YMP.Message.new(publisher_social_graph_host,
                              "yayaka", "social-graph", "remove-subscriber",
                              payload, "yayaka", "social-graph")
    {:ok, answer} = YMP.MessageGateway.request(remove_subscriber)
    if answer["payload"]["body"] == %{} do
      DB.Repo.delete!(subscription)
      body = %{}
      answer = Utils.new_answer(message, body)
      YMP.MessageGateway.push(answer)
    end
  end

  def handle(%{"action" => "add-subscriber"} = message) do
    %{"subscriber-identity-host" => subscriber_identity_host,
      "subscriber-user-id" => subscriber_user_id,
      "publisher-identity-host" => publisher_identity_host,
      "publisher-user-id" => publisher_user_id} = message["payload"]
    sender = Utils.get_sender(message)
    "social-graph" = sender.service
    subscriber = %{
      host: subscriber_identity_host,
      id: subscriber_user_id}
    publisher = %{
      host: publisher_identity_host,
      id: publisher_user_id}
    query = from s in Subscriber,
      where: s.user == ^subscriber,
      where: s.target_user == ^publisher,
      where: s.social_graph == ^sender
    0 = DB.Repo.aggregate(query, :count, :id)
    params = %{
      user: subscriber,
      target_user: publisher,
      social_graph: sender,
      sender: sender}
    changeset = Subscriber.changeset(%Subscriber{}, params)
    user_info = Utils.fetch_user(subscriber_identity_host,
                                 subscriber_user_id,
                                 "social-graph")
    true = Utils.is_authorized(user_info, sender)
    DB.Repo.insert!(changeset)
    body = %{}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  def handle(%{"action" => "remove-subscriber"} = message) do
    %{"subscriber-identity-host" => subscriber_identity_host,
      "subscriber-user-id" => subscriber_user_id,
      "publisher-identity-host" => publisher_identity_host,
      "publisher-user-id" => publisher_user_id} = message["payload"]
    sender = Utils.get_sender(message)
    "social-graph" = sender.service
    subscriber = %{
      host: subscriber_identity_host,
      id: subscriber_user_id}
    publisher = %{
      host: publisher_identity_host,
      id: publisher_user_id}
    query = from s in Subscriber,
      where: s.user == ^subscriber,
      where: s.target_user == ^publisher,
      where: s.social_graph == ^sender
    subscriber = DB.Repo.one!(query)
    user_info = Utils.fetch_user(subscriber_identity_host,
                                 subscriber_user_id,
                                 "social-graph")
    true = Utils.is_authorized(user_info, sender)
    DB.Repo.delete!(subscriber)
    body = %{}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  def handle(%{"action" => "fetch-user-relations"} = message) do
    %{"identity-host" => identity_host,
      "user-id" => user_id} = message["payload"]
    sender = Utils.get_sender(message)
    user = %{host: identity_host, id: user_id}
    query = from subscription in Subscription,
      where: subscription.user == ^user
    subscriptions = DB.Repo.all(query)
                    |> Enum.map(fn subscription ->
                      %{"identity-host" => subscription.target_user.host,
                        "user-id" => subscription.target_user.id,
                        "social-graph-host" => subscription.social_graph.host}
                    end)
    query = from subscriber in Subscriber,
      where: subscriber.target_user == ^user
    subscribers = DB.Repo.all(query)
                  |> Enum.map(fn subscriber ->
                    %{"identity-host" => subscriber.user.host,
                      "user-id" => subscriber.user.id,
                      "social-graph-host" => subscriber.social_graph.host}
                  end)
    body = %{
      "subscriptions" => subscriptions,
      "subscribers" => subscribers}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  defp fetch_timeline(identity_host, user_id, limit) do
    query = from te in TimelineEvent,
      preload: [:event],
      where: te.user == ^%{host: identity_host, id: user_id},
      order_by: [desc: :inserted_at],
      limit: ^limit
    DB.Repo.all(query)
    |> Enum.map(fn timeline_event ->
      event = timeline_event.event
      %{"repository-host" => event.repository.host,
        "event-id" => event.event_id,
        "identity-host" => event.event["identity-host"],
        "user-id" => event.event["user-id"],
        "protocol" => event.event["protocol"],
        "type" => event.event["type"],
        "body" => event.event["body"],
        "sender-host" => event.sender.host,
        "created-at" => Utils.to_datetime(timeline_event.inserted_at)}
    end)
  end

  def handle(%{"action" => "fetch-timeline"} = message) do
    %{"identity-host" => identity_host,
      "user-id" => user_id} = message["payload"]
    limit = message["payload"]["limit"] || 100
    sender = Utils.get_sender(message)
    events = fetch_timeline(identity_host, user_id, limit)
    body = %{"events" => events}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  defp assert_expires(expires) do
    now = DateTime.utc_now |> DateTime.to_unix
    true = (expires - now) <= @max_timeline_subscription_length
  end

  def handle(%{"action" => "subscribe-timeline"} = message) do
    %{"expires" => expires,
      "identity-host" => identity_host,
      "user-id" => user_id} = message["payload"]
    limit = message["payload"]["limit"] || 100
    assert_expires(expires)
    sender = Utils.get_sender(message)
    events = fetch_timeline(identity_host, user_id, limit)
    params = %{
      id: UUID.uuid4(),
      user: %{host: identity_host, id: user_id},
      presentation: sender,
      expires: expires,
      sender: sender}
    changeset = TimelineSubscriber.changeset(%TimelineSubscriber{}, params)
    subscriber = DB.Repo.insert!(changeset)
    body = %{"subscription-id" => subscriber.id, "events" => events, "expires" => expires}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  def handle(%{"action" => "unsubscribe-timeline"} = message) do
    %{"subscription-id" => id} = message["payload"]
    sender = Utils.get_sender(message)
    query = from ts in TimelineSubscriber,
      where: ts.id == ^id,
      where: ts.presentation == ^sender
    DB.Repo.one!(query)
    |> DB.Repo.delete!()
    body = %{}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  def handle(%{"action" => "extend-timeline-subscription"} = message) do
    %{"expires" => expires,
      "subscription-id" => id} = message["payload"]
    assert_expires(expires)
    sender = Utils.get_sender(message)
    query = from ts in TimelineSubscriber,
      where: ts.id == ^id,
      where: ts.presentation == ^sender
    subscriber = DB.Repo.one!(query)
    changeset = Ecto.Changeset.change(subscriber, expires: expires)
    DB.Repo.update!(changeset)
    body = %{"expires" => expires}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  def handle(%{"action" => "broadcast-event",
    "sender" => %{"service" => "repository"}} = message) do
    %{"event-id" => event_id,
      "identity-host" => identity_host,
      "user-id" => user_id,
      "protocol" => protocol,
      "type" => type,
      "body" => body,
      "sender-host" => sender_host,
      "created-at" => created_at} = message["payload"]
    sender = Utils.get_sender(message)
    "repository" = sender.service
    user_info = Utils.fetch_user(identity_host, user_id, "social-graph")
    true = Utils.is_authorized(user_info, sender)
    query = from s in Subscriber,
      where: s.target_user == ^%{host: identity_host, id: user_id}
    DB.Repo.all(query)
    |> Enum.each(fn subscriber ->
      payload = %{
        "repository-host" => sender.host,
        "event-id" => event_id,
        "identity-host" => identity_host,
        "user-id" => user_id,
        "protocol" => protocol,
        "type" => type,
        "body" => body,
        "sender-host" => sender_host,
        "created-at" => created_at}
      push_event = YMP.Message.new(subscriber.social_graph.host,
                                   "yayaka", "social-graph", "broadcast-event",
                                   payload, "yayaka", "social-graph")
      YMP.MessageGateway.push(push_event)
    end)
    body = %{}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end

  def handle(%{"action" => "broadcast-event",
    "sender" => %{"service" => "social-graph"}} = message) do
    %{"repository-host" => repository_host,
      "event-id" => event_id,
      "identity-host" => identity_host,
      "user-id" => user_id,
      "protocol" => protocol,
      "type" => type,
      "body" => body,
      "sender-host" => sender_host,
      "created-at" => created_at} = message["payload"]
    sender = Utils.get_sender(message)
    "social-graph" = sender.service
    user_info = Utils.fetch_user(identity_host, user_id, "social-graph")
    true = Utils.is_authorized(user_info, sender)
    query = from s in Subscription,
      where: s.target_user == ^%{host: identity_host, id: user_id},
      where: s.social_graph == ^sender
    users = DB.Repo.all(query) |> Enum.map(fn subscription -> subscription.user end)
    if length(users) >= 1 do
      event = %{
        "repository-host" => repository_host,
        "event-id" => event_id,
        "identity-host" => identity_host,
        "user-id" => user_id,
        "protocol" => protocol,
        "type" => type,
        "body" => body,
        "sender-host" => sender_host,
        "created-at" => created_at}
      params = %{
        repository: %{host: repository_host, service: :repository},
        event_id: event_id,
        event: event,
        sender: sender}
      event = Event.changeset(%Event{}, params)
              |> DB.Repo.insert!()
      multi = Ecto.Multi.new()
      multi = Enum.reduce(users, multi, fn user, multi ->
        params = %{
          user: user,
          event_id: event.id}
        changeset = TimelineEvent.changeset(%TimelineEvent{}, params)
        Ecto.Multi.insert(multi, user, changeset)
      end)
      {:ok, _} = DB.Repo.transaction(multi)
    end
    now = DateTime.utc_now |> DateTime.to_unix
    query = from ts in TimelineSubscriber,
      where: ts.user in ^users,
      where: ts.expires > ^now
    DB.Repo.all(query)
    |> Enum.each(fn subscription ->
      payload = %{
        "subscription-id" => subscription.id,
        "repository-host" => sender.host,
        "event-id" => event_id,
        "identity-host" => identity_host,
        "user-id" => user_id,
        "protocol" => protocol,
        "type" => type,
        "body" => body,
        "sender-host" => sender_host,
        "created-at" => created_at}
      push_event = YMP.Message.new(subscription.presentation.host,
                                   "yayaka", "social-graph", "push-event",
                                   payload, "yayaka", "social-graph")
      YMP.MessageGateway.push(push_event)
    end)
    body = %{}
    answer = Utils.new_answer(message, body)
    YMP.MessageGateway.push(answer)
  end
end
