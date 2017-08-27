defmodule Web.EventController do
  use Web, :controller

  def timeline(conn, %{"timeline" => params}) do
    %{"social_graph_host" => social_graph_host,
      "identity_host" => identity_host,
      "user_id" => user_id} = params
    data = %{
      social_graph_host: social_graph_host,
      identity_host: identity_host,
      user_id: user_id}
    token = Phoenix.Token.sign(Web.Endpoint, "timeline", data)
    render conn, "timeline.html", token: token
  end

  def timeline(conn, _params) do
    render conn, "timeline.html"
  end
end
