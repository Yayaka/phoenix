defmodule YMP.TestMessageHandler do
  @behaviour YMP.MessageHandler
  @behaviour YMP.AnswerValidator
  @host YMP.get_host()

  def start_link() do
    Registry.start_link(:duplicate, __MODULE__)
  end

  def register(action, host \\ @host) do
    Registry.register(__MODULE__, {host, action}, :ok)
  end

  def unregister(action, host \\ @host) do
    Registry.unregister(__MODULE__, {host, action})
  end

  defmacro with_mocks(do: block) do
    quote do
      {:ok, var!(agent, YMP.TestMessageHandler)} = Agent.start_link(fn -> [] end)
      unquote(block)
      Agent.get(var!(agent, YMP.TestMessageHandler), fn state -> state end)
      |> Enum.each(fn task ->
        assert {:ok, :ok} == Task.yield(task, 10)
      end)
    end
  end

  @host YMP.get_host()
  defmacro mock(host \\ @host, action_name, func) do
    quote bind_quoted: [host: host, action_name: action_name, func: func] do
      if host != @host do
        YMP.TestMessageHandler.represent_remote_host(host)
      end
      task = Task.async(fn ->
        YMP.TestMessageHandler.register(action_name, host)
        receive do
          message ->
            func.(message)
            :ok
          end
      end)
      Agent.update(var!(agent, YMP.TestMessageHandler), fn state ->
        [task | state]
      end)
    end
  end

  def represent_remote_host(host) do
    import Ecto.Query
    query = from h in YMP.HostInformation,
      where: h.host == ^host
    if DB.Repo.aggregate(query, :count, :host) == 0 do
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
    else
      :ok
    end
  end

  def request(module, message, error \\ false) do
    task = Task.async(fn ->
      pid = self()
      YMP.TestMessageHandler.register(message["action"])
      spawn_link fn -> send pid, YMP.MessageGateway.request(message) end
      receive do
        ^message ->
          YMP.TestMessageHandler.unregister(message["action"])
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

  # Callback

  @impl YMP.MessageHandler
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

  @impl YMP.AnswerValidator
  def validate_answer(message) do
    case message["protocol"] do
      "test-answer-validation" ->
        if Map.get(message["payload"], "invalid", false) do
          :error
        else
          :ok
        end
      "yayaka" ->
        Yayaka.MessageHandler.validate_answer(message)
    end
  end
end

