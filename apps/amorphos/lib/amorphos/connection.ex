defmodule Amorphos.Connection do
  @connection_protocols Application.get_env(:amorphos, :connection_protocols)

  @doc """
  Connects to the given host.

  Returns a connection struct.
  """
  @callback connect(host :: %Amorphos.HostInformation{}) :: {:ok, struct} | {:error, any}
  @doc """
  Sends a packet by using the given connection.
  """
  @callback send_packet(connection :: struct, messages :: list(any)) :: :ok | :error
  @doc """
  Validates the connection protocol.
  """
  @callback validate(%Amorphos.HostInformation.ConnectionProtocol{}) :: boolean
  @doc """
  Checks whether the connection is expired or not.
  """
  @callback expires?(connection :: struct) :: true | false

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

  def expires?(connection) do
    apply(connection.__struct__, :expires?, [connection])
  end

  def send_packet(connection, messages) do
    apply(connection.__struct__, :send_packet, [connection, messages])
  end
end
