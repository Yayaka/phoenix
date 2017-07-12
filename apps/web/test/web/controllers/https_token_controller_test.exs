defmodule Web.HTTPSTokenControllerTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  @endpoint Web.Endpoint

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    bypass = Bypass.open
    host_information = %YMP.HostInformation{
      host: "localhost:#{bypass.port}",
      ymp_version: "0.1.0",
      connection_protocols: [
        %YMP.HostInformation.ConnectionProtocol{
          name: "https-token",
          version: "0.1.0",
          parameters: %{
            "request-path" => "/request",
            "grant-path" => "/grant",
            "packet-path" => "/packet"
          }
        }
      ],
      service_protocols: []
    }
    {:ok, bypass: bypass, info: host_information}
  end

  test "POST /api/ymp/https-token/request", %{bypass: bypass, info: info} do
    DB.Repo.insert(info)
    state = "aaaa"
    Bypass.expect_once bypass, "POST", "/grant", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      body = Poison.decode!(body)
      token = body["token"]
      {:ok, claims} = Guardian.decode_and_verify(token)
      assert {:ok, %{"host" => info.host}} == Guardian.serializer.from_token(claims["sub"])
      assert {"content-type", "application/json"} in conn.req_headers
      assert body["host"]  == YMP.get_host()
      assert body["expires"] > DateTime.utc_now() |> DateTime.to_unix()
      assert body["state"] == state
      conn
      |> Plug.Conn.resp(204, "")
    end
    body = %{
      "host" => info.host,
      "state" => state
    } |> Poison.encode!()
    conn = build_conn()
           |> put_req_header("content-type", "application/json")
           |> post "/api/ymp/https-token/request", body
    assert response(conn, 204) == ""
  end

  test "POST /api/ymp/https-token/grant", %{bypass: bypass, info: info} do
    DB.Repo.insert(info)
    state = "aaaa"

    token = "abcd"
    Bypass.expect_once bypass, "POST", "/request", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      body = Poison.decode!(body)
      assert {"content-type", "application/json"} in conn.req_headers
      assert Map.get(body, "host") == YMP.get_host()
      assert Map.get(body, "state") |> String.length() >= 1
      resp_body = %{
        "host" => info.host,
        "token" => token,
        "expires" => (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
        "state" => Map.get(body, "state")
      } |> Poison.encode!()
        conn2 = build_conn()
                |> put_req_header("content-type", "application/json")
                |> post "/api/ymp/https-token/grant", resp_body
        assert response(conn2, 204) == ""
      conn
      |> Plug.Conn.resp(204, "")
    end

    {:ok, connection} = YMP.HTTPSTokenConnection.connect(info)
    assert connection.token == token
    assert connection.expires > DateTime.utc_now() |> DateTime.to_unix()
    assert connection.host_information.host == info.host
  end

  test "POST /api/ymp/https-token/packet", %{bypass: bypass, info: info} do
    action = "web-https-token-controller-packet"
    YMP.TestMessageHandler.register(action)
    host = "host1"
    message = %{"sender" => %{
      "host" => host,
      "protocol" => "protocol1",
      "service" => "service1"},
    "id" => "a",
    "host" => YMP.get_host(),
    "protocol" => "test",
    "service" => "service2",
    "action" => action,
    "payload" => %{
      "text" => "text1"
    }}
    body = %{
      messages: [message]
    }
    resource = %{host: host}
    {:ok, token, _claims} = Guardian.encode_and_sign(resource)
    conn = build_conn()
           |> put_req_header("content-type", "application/json")
           |> put_req_header("authorization", "Bearer #{token}")
           |> post "/api/ymp/https-token/packet", body
    assert response(conn, 204) == ""
    assert_receive(message)
  end
end
