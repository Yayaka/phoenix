defmodule YMP.ConnectionProvider do
  use GenServer

  @connection_protocols Application.get_env(:ymp, :connection_protocols)

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def request(host_information) do
    host = host_information.host
    case GenServer.call(__MODULE__, {:get, host}) do
      nil ->
        case connect(host_information) do
          {:ok, connection} -> {:ok, connection}
          _ -> :error
        end
      connection ->
        if YMP.Connection.check_expired(connection) do
          GenServer.cast(__MODULE__, {:delete, host})
          connect(host_information)
        else
          {:ok, connection}
        end
    end
  end

  defp connect(host_information) do
    with {:ok, protocol} <- YMP.Connection.get_common_connection_protocol(host_information),
         %{module: module} <- Map.get(@connection_protocols, protocol.name),
         {:ok, connection} <- apply(module, :connect, [host_information]) do
      GenServer.cast(__MODULE__, {:put, host_information.host, connection})
      {:ok, connection}
    else
      _ ->
        :error
    end
  end

  def prune_expired do
    GenServer.cast(__MODULE__, :prune_expired)
  end

  def put(host, connection) do
    GenServer.cast(__MODULE__, {:put, host, connection})
  end

  def delete(host) do
    GenServer.cast(__MODULE__, {:delete, host})
  end

  # Callbacks

  def init(_args) do
    {:ok, %{connections: %{}}}
  end

  def handle_cast({:put, host, connection}, state) do
    state = put_in(state, [:connections, host], connection)
    {:noreply, state}
  end

  def handle_cast(:prune_expired, state) do
    connections = Enum.filter(state.connections, fn {_host, connection} ->
      not YMP.Connection.check_expired(connection)
    end) |> Enum.into(%{})
    state = %{state | connections: connections}
    {:noreply, state}
  end

  def handle_cast({:delete, host}, state) do
    connections = Map.delete(state.connections, host)
    state = %{state | connections: connections}
    {:noreply, state}
  end

  def handle_call({:get, host}, _from, state) do
    {:reply, get_in(state, [:connections, host]), state}
  end
end
