defmodule YayakaPresentation.TimelineSubscriptionRegistry do
  alias YayakaPresentation.TimelineSubscription
  import Ecto.Query

  @expires_in 3600 # 1 hour

  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def subscribe(social_graph_host, user, limit \\ 0) do
    social_graph = %{host: social_graph_host, service: :social_graph}
    now = DateTime.utc_now() |> DateTime.to_unix()
    query = from s in TimelineSubscription,
      where: s.user == ^user,
      where: s.social_graph == ^social_graph,
      where: s.expires > ^now
    case DB.Repo.one(query) do
      nil ->
        expires = now + @expires_in
        payload = %{
          "expires" => expires,
          "identity-host" => user.host,
          "user-id" => user.id,
          "limit" => limit}
        subscribe_timeline =
          YMP.Message.new(social_graph_host,
                          "yayaka", "social-graph", "subscribe-timeline",
                          payload, "yayaka", "presentation")
        {:ok, answer} = YMP.MessageGateway.request(subscribe_timeline)
        %{"subscription-id" => subscription_id,
          "expires" => expires,
          "events" => events} = answer["payload"]["body"]
        params = %{
          id: subscription_id,
          user: user,
          social_graph: social_graph,
          expires: expires}
        changeset = TimelineSubscription.changeset(%TimelineSubscription{}, params)
        subscription = DB.Repo.insert!(changeset)
        Registry.register(__MODULE__, subscription.id, :ok)
        {:ok, subscription, events}
      subscription ->
        Registry.register(__MODULE__, subscription.id, :ok)
        {:ok, subscription, []}
    end
  after
    :error
  end

  def unsubscribe(social_graph_host, user) do
    social_graph = %{host: social_graph_host, service: :social_graph}
    now = DateTime.utc_now() |> DateTime.to_unix()
    query = from s in TimelineSubscription,
      where: s.user == ^user,
      where: s.social_graph == ^social_graph,
      where: s.expires > ^now
    subscription = DB.Repo.one!(query)
    DB.Repo.delete!(subscription)
    payload = %{"subscription-id" => subscription.id}
    unsubscribe_timeline =
      YMP.Message.new(social_graph_host,
                      "yayaka", "social-graph", "unsubscribe-timeline",
                      payload, "yayaka", "presentation")
    {:ok, _answer} = YMP.MessageGateway.request(unsubscribe_timeline)
    :ok
  after
    :error
  end

  def extend(social_graph_host, user) do
    social_graph = %{host: social_graph_host, service: :social_graph}
    now = DateTime.utc_now() |> DateTime.to_unix()
    query = from s in TimelineSubscription,
      where: s.user == ^user,
      where: s.social_graph == ^social_graph,
      where: s.expires > ^now
    subscription = DB.Repo.one!(query)
    payload = %{
      "subscription-id" => subscription.id,
      "expires" => now + @expires_in}
    extend_timeline_subscription =
      YMP.Message.new(social_graph_host,
                      "yayaka", "social-graph", "extend-timeline-subscription",
                      payload, "yayaka", "presentation")
    {:ok, answer} = YMP.MessageGateway.request(extend_timeline_subscription)
    %{"expires" => expires} = answer["payload"]["body"]
    changeset = TimelineSubscription.changeset(subscription, %{expires: expires})
    DB.Repo.update!(changeset)
    :ok
  after
    :error
  end

  def push_event(subscription_id, event) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    subscription = DB.Repo.get(TimelineSubscription, subscription_id)
    if subscription.expires > now do
      Registry.dispatch(__MODULE__, subscription.id, fn entries ->
        for {pid, :ok} <- entries do
          send pid, {:event, event}
        end
      end)
    else
      :error
    end
  end
end
