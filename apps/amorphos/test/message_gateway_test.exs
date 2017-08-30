defmodule Amorphos.MessageGatewayTest do
  use DB.DataCase
  import Amorphos.TestMessageHandler, only: [with_mocks: 1, mock: 3]

  test "push to local" do
    Amorphos.TestMessageHandler.register("amorphos-message-gateway-test-push")
    message = %{"sender" => %{
                  "host" => Amorphos.get_host(),
                  "protocol" => "test",
                  "service" => "service1"},
                "id" => "a",
                "host" => Amorphos.get_host(),
                "protocol" => "test",
                "service" => "service2",
                "action" => "amorphos-message-gateway-test-push",
                "payload" => %{
                  "text" => "text1"
                }}
    assert :ok == Amorphos.MessageGateway.push(message)
    assert_receive message
  end

  test "push to remote" do
    host = "host1"
    host_information = %Amorphos.HostInformation{
      host: host,
      amorphos_version: "0.1.0",
      connection_protocols: [
        %Amorphos.HostInformation.ConnectionProtocol{
          name: "test",
          version: "0.1.0",
          parameters: %{}
        }]
    }
    DB.Repo.insert(host_information)
    message = %{"sender" => %{
                  "host" => Amorphos.get_host(),
                  "protocol" => "test",
                  "service" => "service1"},
                "id" => "a",
                "host" => host,
                "protocol" => "test",
                "service" => "service2",
                "action" => "amorphos-message-gateway-test-push",
                "payload" => %{
                  "text" => "text1"
                }}
    Amorphos.TestConnection.register(host)
    assert :ok == Amorphos.MessageGateway.push(message)
    assert_receive [message]
  end

  test "request" do
    pid = self()
    Task.start_link(fn ->
      Amorphos.TestMessageHandler.register("amorphos-message-gateway-test-request")
      send pid, :ok
      receive do
        message ->
          payload = message["payload"]
          sum = payload["list"] |> Enum.sum
          answer = Amorphos.Message.new_answer(message, %{sum: sum})
          Amorphos.MessageGateway.push(answer)
      end
    end)
    receive do
      :ok -> :ok
    end
    message = %{"sender" => %{
                  "host" => Amorphos.get_host(),
                  "protocol" => "test",
                  "service" => "service1"
                },
                "id" => "a",
                "host" => Amorphos.get_host(),
                "protocol" => "test",
                "service" => "service2",
                "action" => "amorphos-message-gateway-test-request",
                "payload" => %{
                  "list" => [1, 2, 3]
                }}
    {:ok, answer} = Amorphos.MessageGateway.request(message)
    assert answer == %{Amorphos.Message.new_answer(message, %{sum: 6}) |
      "id" => answer["id"]}
  end

  test "request and answer_validation" do
    pid = self()
    Task.start_link(fn ->
      Amorphos.TestMessageHandler.register("amorphos-message-gateway-test-request")
      send pid, :ok
      receive do
        message ->
          payload = message["payload"]
          answer = Amorphos.Message.new_answer(message, %{"invalid" => true})
          Amorphos.MessageGateway.push(answer)
      end
    end)
    receive do
      :ok -> :ok
    end
    message = %{"sender" => %{
                  "host" => Amorphos.get_host(),
                  "protocol" => "test-answer-validation",
                  "service" => "service1"
                },
                "id" => "a",
                "host" => Amorphos.get_host(),
                "protocol" => "test-answer-validation",
                "service" => "service2",
                "action" => "amorphos-message-gateway-test-request",
                "payload" => %{}}
    {:error, answer} = Amorphos.MessageGateway.request(message)
    assert answer == %{Amorphos.Message.new_answer(message, %{"invalid" => true}) |
      "id" => answer["id"]}
  end

  test "request to remote" do
    host = "host1"
    pid = self()
    Task.start_link(fn ->
      Amorphos.TestConnection.register(host)
      send pid, :ok
      receive do
        [message] ->
          payload = message["payload"]
          sum = payload["list"] |> Enum.sum
          answer = Amorphos.Message.new_answer(message, %{sum: sum})
          Amorphos.MessageGateway.push(answer)
      end
    end)
    receive do
      :ok -> :ok
    end
    host_information = %Amorphos.HostInformation{
      host: host,
      amorphos_version: "0.1.0",
      connection_protocols: [
        %Amorphos.HostInformation.ConnectionProtocol{
          name: "test",
          version: "0.1.0",
          parameters: %{}
        }]
    }
    DB.Repo.insert(host_information)
    message = %{"sender" => %{
                  "host" => Amorphos.get_host(),
                  "protocol" => "test",
                  "service" => "service1"},
                "id" => "a",
                "host" => host,
                "protocol" => "test",
                "service" => "service2",
                "action" => "amorphos-message-gateway-test-push",
                "payload" => %{
                  "list" => [1, 2, 3]
                }}
    {:ok, answer} = Amorphos.MessageGateway.request(message)
    assert answer == %{Amorphos.Message.new_answer(message, %{sum: 6}) |
      "id" => answer["id"]}
  end

  test "return error when fails" do
    pid = self()
    action = "fail"
    message = %{"sender" => %{
                  "host" => Amorphos.get_host(),
                  "protocol" => "test",
                  "service" => "service1"
                },
                "id" => "a",
                "host" => Amorphos.get_host(),
                "protocol" => "test",
                "service" => "service2",
                "action" => action,
                "payload" => %{
                  "list" => [1, 2, 3]
                }}
    assert :error == Amorphos.MessageGateway.push(message)
  end
end
