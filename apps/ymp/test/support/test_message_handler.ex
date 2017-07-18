defmodule YMP.TestMessageHandler do
  @behaviour YMP.MessageHandler
  def start_link() do
    Registry.start_link(:duplicate, __MODULE__)
  end
  def register(action) do
    Registry.register(__MODULE__, action, :ok)
  end
  # Callback
  def handle(message) do
    action = message["action"]
    Registry.dispatch(__MODULE__, action, fn entries ->
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
              #apply(module.MessageHandler, :handle, [message])
            rescue
              _ -> :ok
            end
          else
            module.handle(message)
            # apply(module, :handle, [message])
          end
      end
      receive do
        x -> x
      end
    end)
    Task.await(task)
  end
end

