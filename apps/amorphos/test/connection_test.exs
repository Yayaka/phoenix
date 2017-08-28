defmodule Amorphos.ConnectionTest do
  use ExUnit.Case

  test "get_common_connection_protocol error" do
    params = %{
      host: "localhost",
      amorphos_version: "0.1.0",
      connection_protocols: [
        %{name: "unknown-protocol",
          version: "0.1.0",
          parameters: %{
          }
        }
      ]
    }
    changeset = Amorphos.HostInformation.changeset(%Amorphos.HostInformation{}, params)
    struct = Ecto.Changeset.apply_changes(changeset)
    assert Amorphos.Connection.get_common_connection_protocol(struct) == :error
  end

  test "get_common_connection_protocol ok" do
    params = %{
      host: "localhost",
      amorphos_version: "0.1.0",
      connection_protocols: [
        %{name: "test",
          version: "0.1.100",
          parameters: %{
            "test" => true
          }
        }
      ]
    }
    changeset = Amorphos.HostInformation.changeset(%Amorphos.HostInformation{}, params)
    struct = Ecto.Changeset.apply_changes(changeset)
    result = Amorphos.Connection.get_common_connection_protocol(struct)
    assert elem(result, 0) == :ok
    assert elem(result, 1).name == "test"
    assert elem(result, 1).version == "0.1.100"
    assert elem(result, 1).parameters |> map_size == 1
  end

  defmodule A do
    @behaviour Amorphos.Connection
    defstruct []
    def connect(_host_information), do: {:ok, %__MODULE__{}}
    def send_packet(_connection, _messages), do: :ok
    def validate(%Amorphos.HostInformation.ConnectionProtocol{}), do: true
    def expires?(_connection), do: true
  end
  defmodule B do
    @behaviour Amorphos.Connection
    defstruct []
    def connect(_host_information), do: {:ok, %__MODULE__{}}
    def send_packet(_connection, _messages), do: :error
    def validate(%Amorphos.HostInformation.ConnectionProtocol{}), do: true
    def expires?(_connection), do: false
  end

  test "expires?" do
    assert Amorphos.Connection.expires?(%A{})
    refute Amorphos.Connection.expires?(%B{})
  end

  test "send_packet" do
    assert :ok == Amorphos.Connection.send_packet(%A{}, [])
    assert :error == Amorphos.Connection.send_packet(%B{}, [])
  end
end
