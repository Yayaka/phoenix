defmodule Web.TimelineChannel do
  use Web, :channel
  alias YayakaPresentation.TimelineSubscriptionRegistry
  alias YayakaPresentation.Event

  def join("timeline", _message, socket) do
    social_graph_host = socket.assigns[:social_graph_host]
    identity_host = socket.assigns[:identity_host]
    user_id = socket.assigns[:user_id]
    user = %{host: identity_host, id: user_id}
    case TimelineSubscriptionRegistry.subscribe(social_graph_host, user, 100) do
      {:ok, subscription, events} ->
        {:ok, events, socket}
      _ ->
        {:error, %{reason: "failed to subscribe"}}
    end
  end

  def handle_in("create_event", message, socket) do
    %{"repository_host" => repository_host,
      "event" => event} = message
    identity_host = socket.assigns[:identity_host]
    user_id = socket.assigns[:user_id]
    user = %{host: identity_host, id: user_id}
    case Event.create(user, repository_host, event) do
      {:ok, id} ->
        {:reply, {:ok, %{event_id: id}}, socket}
      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_info({:event, event}, socket) do
    push socket, "push_event", %{event: event}
    {:noreply, socket}
  end
end
