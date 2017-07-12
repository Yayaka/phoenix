defmodule YMP.MessageGatewayTest do
  use DB.DataCase

  test "push to local" do
    YMP.TestMessageHandler.register("ymp-message-gateway-test-push")
    message = %{"sender" => %{
                  "host" => YMP.get_host(),
                  "protocol" => "test",
                  "service" => "service1"},
                "id" => "a",
                "host" => YMP.get_host(),
                "protocol" => "test",
                "service" => "service2",
                "action" => "ymp-message-gateway-test-push",
                "payload" => %{
                  "text" => "text1"
                }}
    assert :ok == YMP.MessageGateway.push(message)
    assert_receive message
  end

  test "push to remote" do
    host = "host1"
    host_information = %YMP.HostInformation{
      host: host,
      ymp_version: "0.1.0",
      connection_protocols: [
        %YMP.HostInformation.ConnectionProtocol{
          name: "test",
          version: "0.1.0",
          parameters: %{}
        }]
    }
    DB.Repo.insert(host_information)
    message = %{"sender" => %{
                  "host" => YMP.get_host(),
                  "protocol" => "test",
                  "service" => "service1"},
                "id" => "a",
                "host" => host,
                "protocol" => "test",
                "service" => "service2",
                "action" => "ymp-message-gateway-test-push",
                "payload" => %{
                  "text" => "text1"
                }}
    YMP.TestConnection.register(host)
    assert :ok == YMP.MessageGateway.push(message)
    assert_receive [message]
  end

  test "request" do
    pid = self()
    Task.start_link(fn ->
      YMP.TestMessageHandler.register("ymp-message-gateway-test-request")
      send pid, :ok
      receive do
        message ->
          payload = message["payload"]
          sum = payload["list"] |> Enum.sum
          answer = YMP.Message.new_answer(message, %{sum: sum})
          YMP.MessageGateway.push(answer)
      end
    end)
    receive do
      :ok -> :ok
    end
    message = %{"sender" => %{
                  "host" => YMP.get_host(),
                  "protocol" => "test",
                  "service" => "service1"
                },
                "id" => "a",
                "host" => YMP.get_host(),
                "protocol" => "test",
                "service" => "service2",
                "action" => "ymp-message-gateway-test-request",
                "payload" => %{
                  "list" => [1, 2, 3]
                }}
    {:ok, answer} = YMP.MessageGateway.request(message)
    assert answer == %{YMP.Message.new_answer(message, %{sum: 6}) |
      "id" => answer["id"]}
  end

  test "request to remote" do
    host = "host1"
    pid = self()
    Task.start_link(fn ->
      YMP.TestConnection.register(host)
      send pid, :ok
      receive do
        [message] ->
          payload = message["payload"]
          sum = payload["list"] |> Enum.sum
          answer = YMP.Message.new_answer(message, %{sum: sum})
          YMP.MessageGateway.push(answer)
      end
    end)
    receive do
      :ok -> :ok
    end
    host_information = %YMP.HostInformation{
      host: host,
      ymp_version: "0.1.0",
      connection_protocols: [
        %YMP.HostInformation.ConnectionProtocol{
          name: "test",
          version: "0.1.0",
          parameters: %{}
        }]
    }
    DB.Repo.insert(host_information)
    message = %{"sender" => %{
                  "host" => YMP.get_host(),
                  "protocol" => "test",
                  "service" => "service1"},
                "id" => "a",
                "host" => host,
                "protocol" => "test",
                "service" => "service2",
                "action" => "ymp-message-gateway-test-push",
                "payload" => %{
                  "list" => [1, 2, 3]
                }}
    {:ok, answer} = YMP.MessageGateway.request(message)
    assert answer == %{YMP.Message.new_answer(message, %{sum: 6}) |
      "id" => answer["id"]}
  end
end
