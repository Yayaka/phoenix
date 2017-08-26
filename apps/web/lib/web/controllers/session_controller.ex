defmodule Web.SessionController do
  use Web, :controller
  alias YayakaPresentation.User

  plug Guardian.Plug.EnsureAuthenticated,
    %{handler: Web.YayakaUserController} when action in [:switch]

  def create(conn, %{"user" => user_params}) do
    with %{"name" => user_name,
      "password" => user_password} <- user_params,
         {:ok, user} <- User.sign_in(user_name, user_password) do
      conn
      |> Guardian.Plug.sign_in(%{id: user.id, name: user.name})
      |> redirect(to: page_path(conn, :index))
    else
      _ ->
        redirect conn, to: page_path(conn, :login)
    end
  end

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out
    |> redirect to: page_path(conn, :index)
  end

  def switch(conn, %{"host" => identity_host, "id" => user_id}) do
    presetation_user = get_user(conn)
    yayaka_user = %{host: identity_host, id: user_id}
    if User.linked?(presetation_user, yayaka_user) do
      conn
      |> put_session(:yayaka_user, yayaka_user)
      |> redirect(to: page_path(conn, :index))
    else
      conn
      |> redirect(to: page_path(conn, :index))
    end
  end
end
