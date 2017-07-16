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
end
