defmodule Amorphos.HTTPSTokenConnectionTest do
  use DB.DataCase

  setup do
    bypass = Bypass.open
    host_information = %Amorphos.HostInformation{
      host: "localhost:#{bypass.port}",
      amorphos_version: "0.1.0",
      connection_protocols: [
        %Amorphos.HostInformation.ConnectionProtocol{
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
      assert Map.get(body, "host") == Amorphos.get_host()
      assert Map.get(body, "state") |> String.length() >= 1
      map = %{
        "host" => info.host,
        "token" => token,
        "expires" => (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
        "state" => Map.get(body, "state")
      }
      Amorphos.HTTPSTokenConnection.handle_grant(map)
      conn
      |> Plug.Conn.resp(204, "")
    end

    {:ok, connection} = Amorphos.HTTPSTokenConnection.connect(info)
    assert connection.token == token
    assert connection.expires > DateTime.utc_now() |> DateTime.to_unix()
    assert connection.host_information.host == info.host
  end

  test "connect with invalid state", %{bypass: bypass, info: info} do
    Bypass.expect_once bypass, "POST", "/request", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      body = Poison.decode!(body)
      assert {"content-type", "application/json"} in conn.req_headers
      assert Map.get(body, "host") == Amorphos.get_host()
      assert Map.get(body, "state") |> String.length() >= 1
      map = %{
        "host" => info.host,
        "token" => "aaaa",
        "expires" => (DateTime.utc_now() |> DateTime.to_unix()) + 1000,
        "state" => Map.get(body, "state") <> "a" # invalid state
      }
      Amorphos.HTTPSTokenConnection.handle_grant(map)
      conn
      |> Plug.Conn.resp(204, "")
    end

    assert {:error, "timeout"} == Amorphos.HTTPSTokenConnection.connect(info)
  end

  test "validate" do
    valid = %Amorphos.HostInformation.ConnectionProtocol{
      name: "https-token",
      version: "0.1.0",
      parameters: %{
        "request-path" => "/",
        "grant-path" => "/",
        "packet-path" => "/"
      }
    }
    assert Amorphos.HTTPSTokenConnection.validate(valid)

    invalid = %Amorphos.HostInformation.ConnectionProtocol{
      name: "https-token",
      version: "0.1.0",
      parameters: %{
        "request-path" => "",
        "grant-path" => "",
        "packet-path" => ""
      }
    }
    refute Amorphos.HTTPSTokenConnection.validate(invalid)
  end

  test "expires?", %{info: info} do
    token = "aaaa"
    now = DateTime.utc_now() |> DateTime.to_unix()
    expired = %Amorphos.HTTPSTokenConnection{
      host_information: info,
      token: token,
      expires: now - 1000
    }
    not_expired = %Amorphos.HTTPSTokenConnection{
      host_information: info,
      token: token,
      expires: now + 1000
    }
    assert Amorphos.HTTPSTokenConnection.expires?(expired)
    refute Amorphos.HTTPSTokenConnection.expires?(not_expired)
  end

  test "send_packet", %{bypass: bypass, info: info} do
    token = "aaaa"
    sender_host = Amorphos.get_host()
    connection = %Amorphos.HTTPSTokenConnection{
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
    assert :ok == Amorphos.HTTPSTokenConnection.send_packet(connection, messages)
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
      assert body["host"]  == Amorphos.get_host()
      assert body["expires"] > DateTime.utc_now() |> DateTime.to_unix()
      assert body["state"] == state
      conn
      |> Plug.Conn.resp(204, "")
    end
    map = %{"host" => info.host,
      "state" => state}
    assert :ok == Amorphos.HTTPSTokenConnection.handle_request(map)
  end

  test "handle_packet" do
    action = "amorphos-https-token-connection-test-handle-packet"
    Amorphos.TestMessageHandler.register(action)
    host = Amorphos.get_host()
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
    Amorphos.HTTPSTokenConnection.handle_packet(%{host: "host1"}, packet)
    assert_receive message1
    refute_receive message2
    refute_receive message3
    refute_receive message4
  end
end
