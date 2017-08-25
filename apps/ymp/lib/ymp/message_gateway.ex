defmodule YMP.MessageGateway do
  if Mix.env == :test do
    @timeout 200
  else
    @timeout 5000
  end

  @service_protocols Application.get_env(:ymp, :service_protocols)

  defp handle_message(message) do
    case Map.get(@service_protocols, message["protocol"]) do
      nil -> :error
      %{module: module} ->
        apply(module, :handle, [message])
    end
  end

  def push(message) do
    host = message["host"]
    to_me = host == YMP.get_host()
    is_answer = Map.has_key?(message, "reply-to")
    if to_me do
      if is_answer do
        handle_reply(message)
      else
        handle_message(message)
      end
    else
      with {:ok, host_information} <- YMP.HostInformationProvider.request(host),
           {:ok, connection} = YMP.ConnectionProvider.request(host_information) do
        YMP.Connection.send_packet(connection, [message])
        :ok
      else
        _ ->
          :error
      end
    end
  end

  def request(message) do
    Registry.register(__MODULE__, message["id"], :ok)
    push(message)
    receive do
      {:message, message} ->
        case Map.get(@service_protocols, message["protocol"]) do
          %{module: module, answer_validation: true} ->
            IO.inspect(apply(module, :validate_answer, [message]))
            case apply(module, :validate_answer, [message]) do
              :ok -> {:ok, message}
              :error -> {:error, message}
            end
          _ -> {:ok, message}
        end
    after
      @timeout -> :timeout
    end
  after
    # Unregister explicitly
    Registry.unregister(__MODULE__, message["id"])
  end

  defp handle_reply(message) do
    id = message["reply-to"]
    Registry.dispatch(__MODULE__, id, fn entries ->
      for {pid, :ok} <- entries do
        send pid, {:message, message}
      end
    end)
    :ok
  end
end
