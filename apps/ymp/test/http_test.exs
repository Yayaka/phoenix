defmodule YMP.HTTPTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open
    {:ok, bypass: bypass}
  end

  test "get", %{bypass: bypass} do
    Bypass.expect_once bypass, "GET", "/path", fn conn ->
      assert {"content-type", "application/json"} in conn.req_headers
      assert {:ok, "aaaa"} == Plug.Conn.read_body(conn) |> Tuple.delete_at(2)
      body = "bbbb"
      conn
      |> Plug.Conn.send_resp(200, body)
    end
    url = "http://localhost:#{bypass.port}/path"
    body = "aaaa"
    headers = [{"Content-Type", "application/json"}]
    {:ok, response} = YMP.HTTP.get(url, body, headers)
    assert "bbbb" == response.body
  end

  test "post", %{bypass: bypass} do
    Bypass.expect_once bypass, "POST", "/path", fn conn ->
      assert {"content-type", "application/json"} in conn.req_headers
      assert {:ok, "aaaa"} == Plug.Conn.read_body(conn) |> Tuple.delete_at(2)
      body = "bbbb"
      conn
      |> Plug.Conn.send_resp(200, body)
    end
    url = "http://localhost:#{bypass.port}/path"
    body = "aaaa"
    headers = [{"Content-Type", "application/json"}]
    {:ok, response} = YMP.HTTP.post(url, body, headers)
    assert "bbbb" == response.body
  end
end
