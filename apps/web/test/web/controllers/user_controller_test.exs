defmodule Web.UserControllerTest do
  use Web.ConnCase

  alias YayakaPresentation.PresentationUser
  @valid_attrs %{name: "some name", password: "some password"}
  @invalid_attrs %{}

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, user_path(conn, :new)
    assert html_response(conn, 200) =~ "New user"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, user_path(conn, :create), user: @valid_attrs
    assert redirected_to(conn) == page_path(conn, :index)
    user = DB.Repo.get_by(PresentationUser, %{name: @valid_attrs.name})
    assert user != nil
    assert Guardian.Plug.current_resource(conn) == %{id: user.id, name: user.name}
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, user_path(conn, :create), user: @invalid_attrs
    assert redirected_to(conn) == user_path(conn, :new)
  end
end
