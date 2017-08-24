defmodule Web.UserController do
  use Web, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user_params}) do
    with %{"name" => user_name,
      "password" => user_password} <- user_params,
         {:ok, user} <- YayakaPresentation.User.sign_up(user_name, user_password) do
      conn
      |> Guardian.Plug.sign_in(%{id: user.id, name: user.name})
      |> redirect(to: page_path(conn, :index))
    else
      _ ->
        redirect conn, to: user_path(conn, :new)
    end
  end
end
