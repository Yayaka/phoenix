defmodule YMP.HTTPSTokenConnectionTest do
  use DB.DataCase

  setup_all do
    YMP.TestMessageHandler.start_link()
    :ok
  end

  setup do
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

  test "connect valid state", %{bypass: bypass, info: info} do
    token = "abcd"
    Bypass.expect_once bypass, "POST", "/request", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      body = Poison.decode!(body)
      assert {"content-type", "application/json"} in conn.req_headers
      assert Map.get(body, "host") == YMP.get_host()
      assert Map.get(body, "state") |> String.length() >= 1
      map = %{
        "host" => info.host,
        "token" => token,
        "expires" => (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
        "state" => Map.get(body, "state")
      }
      YMP.HTTPSTokenConnection.handle_grant(map)
      conn
      |> Plug.Conn.resp(204, "")
    end

    {:ok, connection} = YMP.HTTPSTokenConnection.connect(info)
    assert connection.token == token
    assert connection.expires > DateTime.utc_now() |> DateTime.to_unix()
    assert connection.host_information.host == info.host
  end

  test "connect with invalid state", %{bypass: bypass, info: info} do
    Bypass.expect_once bypass, "POST", "/request", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      body = Poison.decode!(body)
      assert {"content-type", "application/json"} in conn.req_headers
      assert Map.get(body, "host") == YMP.get_host()
      assert Map.get(body, "state") |> String.length() >= 1
      map = %{
        "host" => info.host,
        "token" => "aaaa",
        "expires" => (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
        "state" => Map.get(body, "state") <> "a" # invalid state
      }
      YMP.HTTPSTokenConnection.handle_grant(map)
      conn
      |> Plug.Conn.resp(204, "")
    end

    assert {:error, "timeout"} == YMP.HTTPSTokenConnection.connect(info)
  end

  test "validate" do
    valid = %YMP.HostInformation.ConnectionProtocol{
      name: "https-token",
      version: "0.1.0",
      parameters: %{
        "request-path" => "/",
        "grant-path" => "/",
        "packet-path" => "/"
      }
    }
    assert YMP.HTTPSTokenConnection.validate(valid)

    invalid = %YMP.HostInformation.ConnectionProtocol{
      name: "https-token",
      version: "0.1.0",
      parameters: %{
        "request-path" => "",
        "grant-path" => "",
        "packet-path" => ""
      }
    }
    refute YMP.HTTPSTokenConnection.validate(invalid)
  end

  test "check_expired", %{info: info} do
    token = "aaaa"
    now = DateTime.utc_now() |> DateTime.to_unix()
    not_expired = %YMP.HTTPSTokenConnection{
      host_information: info,
      token: token,
      expires: now + 1000
    }
    expired = %YMP.HTTPSTokenConnection{
      host_information: info,
      token: token,
      expires: now - 1000
    }
    assert YMP.HTTPSTokenConnection.check_expired(expired)
    refute YMP.HTTPSTokenConnection.check_expired(not_expired)
  end

  test "send_packet", %{bypass: bypass, info: info} do
    token = "aaaa"
    sender_host = YMP.get_host()
    connection = %YMP.HTTPSTokenConnection{
      host_information: info,
      token: token,
      expires: DateTime.utc_now() |> DateTime.to_unix()
    }
    Bypass.expect_once bypass, "POST", "/packet", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      body = Poison.decode!(body)
      messages = get_in(body, ["packet", "messages"])
      message = hd(messages)
      assert {"content-type", "application/json"} in conn.req_headers
      assert {"authorization", "Bearer #{token}"} in conn.req_headers
      assert length(messages) == 1
      assert message["host"]  == info.host
      assert message["action"] == "action1"
      conn
      |> Plug.Conn.resp(204, "")
    end

    messages = [%{"sender" => %{
                  "host" => sender_host,
                  "protocol" => "protocol1",
                  "service" => "service1"},
                "id" => "a",
                "host" => connection.host_information.host,
                "protocol" => "protocol2",
                "service" => "service2",
                "action" => "action1",
                "payload" => %{
                  "text" => "text1"
                }}]
    assert :ok == YMP.HTTPSTokenConnection.send_packet(connection, messages)
  end

  test "handle_request", %{bypass: bypass, info: info} do
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
    map = %{"host" => info.host,
      "state" => state}
    assert :ok == YMP.HTTPSTokenConnection.handle_request(map)
  end

  test "handle_packet" do
    action = "ymp-https-token-connection-test-handle-packet"
    YMP.TestMessageHandler.register(action)
    host = YMP.get_host()
    message1 = %{"sender" => %{
      "host" => "host1",
      "protocol" => "protocol1",
      "service" => "service1"},
    "id" => "a",
    "host" => host,
    "protocol" => "test",
    "service" => "service2",
    "action" => action,
    "payload" => %{
      "text" => "text1"
    }}
    message2 = message1
               |> put_in(["sender", "host"], "host2")
    message3 = message1
               |> put_in(["host"], "host1")
    message4 = message1
               |> put_in(["sender", "host"], "host2")
               |> put_in(["host"], "host1")
    packet = %{
      "messages" => [message1, message2, message3, message4]
    }
    YMP.HTTPSTokenConnection.handle_packet(%{host: "host1"}, packet)
    assert_receive message1
    refute_receive message2
    refute_receive message3
    refute_receive message4
  end
end
