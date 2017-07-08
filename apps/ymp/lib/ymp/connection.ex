defmodule YMP.Connection do
  @connection_protocols Application.get_env(:ymp, :connection_protocols)

  @doc """
  Connects to the given host.

  Returns a connection struct.
  """
  @callback connect(host :: %YMP.HostInformation{}) :: {:ok, struct} | :error
  @doc """
  Sends a packet by using the given connection.
  """
  @callback send_packet(connection :: struct, messages :: list(any)) :: :ok | :error
  @doc """
  Validate the connection protocol.
  """
  @callback validate(%YMP.HostInformation.ConnectionProtocol{}) :: boolean

  def get_common_connection_protocol(host_information) do
    case get_common_connection_protocols(host_information) do
      [] -> :error
      [head | _] -> {:ok, head}
    end
  end

  def get_common_connection_protocols(host_information) do
    host_information.connection_protocols
    |> Enum.filter(fn %{name: name} ->
      List.keymember?(@connection_protocols, name, 0)
    end)
  end
end
