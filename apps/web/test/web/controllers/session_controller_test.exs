defmodule Web.SessionControllerTest do
  use Web.ConnCase

  test "sign in when password is correct", %{conn: conn} do
    name = "name1"
    password = "password1"
    {:ok, user} = YayakaPresentation.User.sign_up(name, password)
    conn = post conn, session_path(conn, :create), user: %{name: name, password: password}
    assert redirected_to(conn) == page_path(conn, :index)
    assert Guardian.Plug.current_resource(conn) == %{id: user.id, name: user.name}
  end

  test "does not sign in when data is not correct", %{conn: conn} do
    name = "name1"
    password = "password1"
    {:ok, _} = YayakaPresentation.User.sign_up(name, password <> "aaa")
    conn = post conn, session_path(conn, :create), user: %{name: name, password: password}
    assert redirected_to(conn) == page_path(conn, :login)
    assert Guardian.Plug.current_resource(conn) == nil
  end

  test "sign out", %{conn: conn} do
    {:ok, user} = YayakaPresentation.User.sign_up("name1", "password1")
    conn = conn
           |> bypass_through(Web.Router, :browser)
           |> get("/")
           |> Guardian.Plug.sign_in(%{id: user.id, name: user.name})
           |> send_resp(:ok, "")
    conn = get conn, session_path(conn, :delete)
    assert Guardian.Plug.current_resource(conn) == nil
  end
end
