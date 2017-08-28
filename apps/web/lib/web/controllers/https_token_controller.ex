defmodule Web.HTTPSTokenController do
  use Web, :controller
  plug Guardian.Plug.EnsureAuthenticated, [handler: __MODULE__] when action in [:packet]

  def request(conn, _params) do
    with %{"host" => host, "state" => state} = body <- conn.params,
         ["application/json"] <- get_req_header(conn, "content-type"),
         :ok <- Amorphos.HTTPSTokenConnection.handle_request(body) do
      conn
      |> Plug.Conn.resp(204, "")
    else
      _ ->
        conn
        |> Plug.Conn.resp(204, "")
    end
  end

  def grant(conn, _params) do
    with %{"host" => host,
           "token" => token,
           "expires" => expires,
           "state" => state} = body <- conn.params,
         ["application/json"] <- get_req_header(conn, "content-type"),
         :ok <- Amorphos.HTTPSTokenConnection.handle_grant(body) do
      conn
      |> Plug.Conn.resp(204, "")
    else
      _ ->
        conn
        |> Plug.Conn.resp(204, "")
    end
  end

  def packet(conn, _params) do
    with resource <- Guardian.Plug.current_resource(conn),
         ["application/json"] <- get_req_header(conn, "content-type"),
         %{"packet" => packet} = body <- conn.params,
         :ok <- Amorphos.HTTPSTokenConnection.handle_packet(resource, body) do
      conn
      |> Plug.Conn.resp(204, "")
    else
      _ ->
        conn
        |> Plug.Conn.resp(204, "")
    end
  end

  # Guardian callback
  def unauthenticated(conn, _params) do
    conn
    |> put_status(401)
    |> render "error.json", message: "Authentication required"
  end
end
