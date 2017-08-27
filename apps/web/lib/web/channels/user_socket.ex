defmodule Web.UserSocket do
  use Phoenix.Socket

  channel "timeline", Web.TimelineChannel

  transport :websocket, Phoenix.Transports.WebSocket
  def connect(%{"token" => token}, socket) do
    # max_age: 1209600 is equivalent to two weeks in seconds
    case Phoenix.Token.verify(Web.Endpoint, "timeline", token, max_age: 1209600) do
      {:ok, map} ->
        socket = socket
                 |> assign(:social_graph_host, map.social_graph_host)
                 |> assign(:identity_host, map.identity_host)
                 |> assign(:user_id, map.user_id)
        {:ok, socket}
      {:error, reason} ->
        :error
    end
  end

  def id(_socket), do: nil
end
