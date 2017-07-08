defmodule YMP.MessageGateway do
  @timeout 5000

  def start_link(_opts \\ []) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def request(message, opts \\ []) do
    noreply = Keyword.get(opts, :noreply, false)
    try do
      unless noreply do
        wait_reply(message)
      else
        # TODO push message
        :ok
      end
    rescue
      _ -> :error
    end
  end

  defp wait_reply(message) do
    Registry.register(__MODULE__, message["id"], :ok)
    # TODO push message
    receive do
      {:message, message} -> {:ok, message}
    after
      @timeout -> :timeout
    end
  after
    # Unregister explicitly
    Registry.unregister(__MODULE__, message["id"])
  end

  def handle_reply(message) do
    id = message["reply-to"]
    Registry.dispatch(__MODULE__, id, fn entries ->
      for {pid, :ok} <- entries do
        send pid, {:message, message}
      end
    end)
  end
end
