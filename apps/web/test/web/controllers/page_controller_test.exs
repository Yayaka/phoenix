defmodule Web.PageControllerTest do
  use Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Yayaka Reference"
  end

  test "GET /login", %{conn: conn} do
    conn = get conn, "/login"
    assert html_response(conn, 200) =~ "Sign in"
  end

  test "GET /.well-known/amorphos", %{conn: conn} do
    conn = get conn, "/.well-known/amorphos"
    body = json_response(conn, 200)
    host_information = Application.get_env(:amorphos, :host_information)
    assert body["amorphos-version"] == host_information["amorphos-version"]
    connection_protocols = body["connection-protocols"]
    assert length(connection_protocols) ==
      length(host_information["connection-protocols"])
    service_protocols = body["service-protocols"]
    assert length(service_protocols) ==
      length(host_information["service-protocols"])
  end
end
