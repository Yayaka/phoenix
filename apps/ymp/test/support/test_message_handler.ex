defmodule YMP.TestMessageHandler do
  @behaviour YMP.MessageHandler
  def start_link() do
    Registry.start_link(:unique, __MODULE__)
  end
  def register(action) do
    Registry.register(__MODULE__, action, :ok)
  end
  # Callback
  def handle(message) do
    action = message["action"]
    Registry.dispatch(__MODULE__, action, fn entries ->
      for {pid, :ok} <- entries do
        send pid, message
      end
    end)
    Registry.unregister(__MODULE__, action)
    :ok
  end
end

