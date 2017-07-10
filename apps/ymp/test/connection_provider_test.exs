defmodule YMP.ConnectionProviderTest do
  use ExUnit.Case

  defmodule A do
    @behaviour YMP.Connection
    defstruct [:id]
    def connect(_host_information), do: {:ok, %__MODULE__{id: UUID.uuid4()}}
    def send_packet(_connection, _messages), do: :error
    def validate(%YMP.HostInformation.ConnectionProtocol{}), do: true
    def check_expired(_connection), do: true
  end
  defmodule B do
    @behaviour YMP.Connection
    defstruct [:id]
    def connect(_host_information), do: {:ok, %__MODULE__{id: UUID.uuid4()}}
    def send_packet(_connection, _messages), do: :error
    def validate(%YMP.HostInformation.ConnectionProtocol{}), do: true
    def check_expired(_connection), do: false
  end

  @host_a1 %YMP.HostInformation{
    host: "a1.localhost",
    ymp_version: "0.1.0",
    connection_protocols: [
      %YMP.HostInformation.ConnectionProtocol{
        name: "test-a", version: "0.1.0", parameters: %{}
      }],
    service_protocols: []
  }
  @host_a2 %YMP.HostInformation{
    host: "a2.localhost",
    ymp_version: "0.1.0",
    connection_protocols: [
      %YMP.HostInformation.ConnectionProtocol{
        name: "test-a", version: "0.1.0", parameters: %{}
      }],
    service_protocols: []
  }
  @host_b1 %YMP.HostInformation{
    host: "b1.localhost",
    ymp_version: "0.1.0",
    connection_protocols: [
      %YMP.HostInformation.ConnectionProtocol{
        name: "test-b", version: "0.1.0", parameters: %{}
      }],
    service_protocols: []
  }
  @host_b2 %YMP.HostInformation{
    host: "b2.localhost",
    ymp_version: "0.1.0",
    connection_protocols: [
      %YMP.HostInformation.ConnectionProtocol{
        name: "test-b", version: "0.1.0", parameters: %{}
      }],
    service_protocols: []
  }

  setup do
    :sys.replace_state(YMP.ConnectionProvider, fn _ -> %{connections: %{}} end)
  end

  test "request/1 only connects if not existed or expired" do
    {:ok, connection1} = YMP.ConnectionProvider.request(@host_a1)
    {:ok, connection2} = YMP.ConnectionProvider.request(@host_a1)
    assert connection1.id != connection2.id
    {:ok, connection} = YMP.ConnectionProvider.request(@host_b1)
    assert {:ok, connection} == YMP.ConnectionProvider.request(@host_b1)
    state = :sys.get_state(YMP.ConnectionProvider)
    assert state.connections |> map_size == 2
    assert state.connections[@host_a1.host].__struct__ == __MODULE__.A
    assert state.connections[@host_b1.host].__struct__ == __MODULE__.B
  end

  test "prune_expired" do
    {:ok, _} = YMP.ConnectionProvider.request(@host_a1)
    {:ok, _} = YMP.ConnectionProvider.request(@host_a2)
    {:ok, connection1} = YMP.ConnectionProvider.request(@host_b1)
    {:ok, connection2} = YMP.ConnectionProvider.request(@host_b2)
    state = :sys.get_state(YMP.ConnectionProvider)
    assert state.connections |> map_size == 4
    YMP.ConnectionProvider.prune_expired()
    state = :sys.get_state(YMP.ConnectionProvider)
    assert state.connections |> map_size == 2
    assert state.connections[@host_b1.host] == connection1
    assert state.connections[@host_b2.host] == connection2
  end

  test "put" do
    {:ok, connection1} = __MODULE__.A.connect(:ok)
    {:ok, connection2} = __MODULE__.A.connect(:ok)
    YMP.ConnectionProvider.put(@host_a1.host, connection1)
    YMP.ConnectionProvider.put(@host_a2.host, connection2)
    state = :sys.get_state(YMP.ConnectionProvider)
    assert state.connections |> map_size == 2
    assert state.connections[@host_a1.host] == connection1
    assert state.connections[@host_a2.host] == connection2
  end

  test "delete" do
    {:ok, connection1} = __MODULE__.A.connect(:ok)
    {:ok, connection2} = __MODULE__.A.connect(:ok)
    YMP.ConnectionProvider.put(@host_a1.host, connection1)
    YMP.ConnectionProvider.put(@host_a2.host, connection1)
    state = :sys.get_state(YMP.ConnectionProvider)
    assert state.connections |> map_size == 2
    YMP.ConnectionProvider.delete(@host_a1.host)
    YMP.ConnectionProvider.delete(@host_a2.host)
    state = :sys.get_state(YMP.ConnectionProvider)
    assert state.connections |> map_size == 0
  end
end
