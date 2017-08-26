defmodule Web.SessionControllerTest do
  use Web.ConnCase
  alias YayakaPresentation.UserLink

  def sign_in(conn, user) do
    conn
    |> bypass_through(Web.Router, :browser)
    |> get("/")
    |> Guardian.Plug.sign_in(%{id: user.id, name: user.name})
    |> send_resp(:ok, "")
  end

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
           |> sign_in(user)
    conn = get conn, session_path(conn, :delete)
    assert Guardian.Plug.current_resource(conn) == nil
  end

  test "switch user", %{conn: conn} do
    {:ok, presetation_user} = YayakaPresentation.User.sign_up("name1", "password")
    user1 = %{host: "host1", id: "id1"}
    link = DB.Repo.insert!(%UserLink{presentation_user_id: presetation_user.id, user: user1})
    conn = conn
           |> sign_in(presetation_user)
           |> get(session_path(conn, :switch), host: user1.host, id: user1.id)
    assert redirected_to(conn) == page_path(conn, :index)
    assert get_session(conn, :yayaka_user) == user1
  end

  test "switch not authorized user", %{conn: conn} do
    {:ok, presetation_user} = YayakaPresentation.User.sign_up("name1", "password")
    {:ok, presetation_user2} = YayakaPresentation.User.sign_up("name2", "password")
    user1 = %{host: "host1", id: "id1"}
    link = DB.Repo.insert!(%UserLink{presentation_user_id: presetation_user2.id, user: user1})
    conn = conn
           |> sign_in(presetation_user)
           |> get(session_path(conn, :switch), host: user1.host, id: user1.id)
    assert redirected_to(conn) == page_path(conn, :index)
    assert get_session(conn, :yayaka_user) == nil
  end
end
