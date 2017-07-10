defmodule YMP.ConnectionTest do
  use ExUnit.Case

  test "get_common_connection_protocol error" do
    params = %{
      host: "localhost",
      ymp_version: "0.1.0",
      connection_protocols: [
        %{name: "unknown-protocol",
          version: "0.1.0",
          parameters: %{
          }
        }
      ]
    }
    changeset = YMP.HostInformation.changeset(%YMP.HostInformation{}, params)
    struct = Ecto.Changeset.apply_changes(changeset)
    assert YMP.Connection.get_common_connection_protocol(struct) == :error
  end

  test "get_common_connection_protocol ok" do
    params = %{
      host: "localhost",
      ymp_version: "0.1.0",
      connection_protocols: [
        %{name: "test",
          version: "0.1.100",
          parameters: %{
            "test" => true
          }
        }
      ]
    }
    changeset = YMP.HostInformation.changeset(%YMP.HostInformation{}, params)
    struct = Ecto.Changeset.apply_changes(changeset)
    result = YMP.Connection.get_common_connection_protocol(struct)
    assert elem(result, 0) == :ok
    assert elem(result, 1).name == "test"
    assert elem(result, 1).version == "0.1.100"
    assert elem(result, 1).parameters |> map_size == 1
  end

  defmodule A do
    @behaviour YMP.Connection
    defstruct []
    def connect(_host_information), do: {:ok, %__MODULE__{}}
    def send_packet(_connection, _messages), do: :ok
    def validate(%YMP.HostInformation.ConnectionProtocol{}), do: true
    def check_expired(_connection), do: true
  end
  defmodule B do
    @behaviour YMP.Connection
    defstruct []
    def connect(_host_information), do: {:ok, %__MODULE__{}}
    def send_packet(_connection, _messages), do: :error
    def validate(%YMP.HostInformation.ConnectionProtocol{}), do: true
    def check_expired(_connection), do: false
  end

  test "check_expired" do
    assert YMP.Connection.check_expired(%A{})
    refute YMP.Connection.check_expired(%B{})
  end

  test "send_packet" do
    assert :ok == YMP.Connection.send_packet(%A{}, [])
    assert :error == YMP.Connection.send_packet(%B{}, [])
  end
end
