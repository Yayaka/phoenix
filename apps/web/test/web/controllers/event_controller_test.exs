defmodule Web.EventControllerTest do
  use Web.ConnCase

  test "GET /timeline", %{conn: conn} do
    conn = get conn, "/timeline"
    assert html_response(conn, 200) =~ "Timeline"
  end
end
