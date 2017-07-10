defmodule YMP.Connection do
  @connection_protocols Application.get_env(:ymp, :connection_protocols)

  @doc """
  Connects to the given host.

  Returns a connection struct.
  """
  @callback connect(host :: %YMP.HostInformation{}) :: {:ok, struct} | {:error, any}
  @doc """
  Sends a packet by using the given connection.
  """
  @callback send_packet(connection :: struct, messages :: list(any)) :: :ok | :error
  @doc """
  Validates the connection protocol.
  """
  @callback validate(%YMP.HostInformation.ConnectionProtocol{}) :: boolean
  @doc """
  Checks whether the connection is expired or not.
  """
  @callback check_expired(connection :: struct) :: true | false

  def get_common_connection_protocol(host_information) do
    case get_common_connection_protocols(host_information) do
      [] -> :error
      [head | _] -> {:ok, head} # TODO Prioritization
    end
  end

  defp get_common_connection_protocols(host_information) do
    host_information.connection_protocols
    |> Enum.filter(fn %{name: name} ->
      Map.has_key?(@connection_protocols, name)
    end)
  end

  def check_expired(connection) do
    apply(connection.__struct__, :check_expired, [connection])
  end

  def send_packet(connection, messages) do
    apply(connection.__struct__, :send_packet, [connection, messages])
  end
end
