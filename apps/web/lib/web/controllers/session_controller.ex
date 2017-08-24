defmodule Web.SessionController do
  use Web, :controller

  def create(conn, %{"user" => user_params}) do
    with %{"name" => user_name,
      "password" => user_password} <- user_params,
         {:ok, user} <- YayakaPresentation.User.sign_in(user_name, user_password) do
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
end
