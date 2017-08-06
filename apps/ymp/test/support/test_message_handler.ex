defmodule YMP.TestMessageHandler do
  @behaviour YMP.MessageHandler
  @host YMP.get_host()
  def start_link() do
    Registry.start_link(:duplicate, __MODULE__)
  end
  def register(action, host \\ @host) do
    Registry.register(__MODULE__, {host, action}, :ok)
  end
  def represent_remote_host(host) do
    pid = self()
    host_information = %YMP.HostInformation{
      host: host,
      ymp_version: "0.1.0",
      connection_protocols: [
        %YMP.HostInformation.ConnectionProtocol{
          name: "test",
          version: "0.1.0",
          parameters: %{}
        }]}
    DB.Repo.insert(host_information)
    spawn_link fn ->
      YMP.TestConnection.register(host)
      send pid, :ok
      for :ok <- Stream.cycle([:ok]) do
        receive do
          messages ->
            for message <- messages do
              handle(message)
            end
        end
      end
    end
    receive do
      :ok -> :ok
    end
  end
  # Callback
  def handle(message) do
    host = message["host"]
    action = message["action"]
    Registry.dispatch(__MODULE__, {host, action}, fn entries ->
      Enum.uniq(entries)
      |> Enum.each(fn {pid, :ok} ->
        send pid, message
      end)
    end)
    :ok
  end

  def request(module, message, error \\ false) do
    task = Task.async(fn ->
      pid = self()
      YMP.TestMessageHandler.register(message["action"])
      spawn_link fn -> send pid, YMP.MessageGateway.request(message) end
      receive do
        ^message ->
          if error do
            try do
              module.handle(message)
            rescue
              _ -> :ok
            end
          else
            module.handle(message)
          end
      end
      receive do
        x -> x
      end
    end)
    Task.await(task)
  end
end

