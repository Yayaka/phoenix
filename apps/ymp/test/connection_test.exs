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
        %{name: "https-token",
          version: "0.1.100",
          parameters: %{
            "request-path" => "/request",
            "grant-path" => "/grant",
            "packet-path" => "/packet"
          }
        }
      ]
    }
    changeset = YMP.HostInformation.changeset(%YMP.HostInformation{}, params)
    struct = Ecto.Changeset.apply_changes(changeset)
    result = YMP.Connection.get_common_connection_protocol(struct)
    assert elem(result, 0) == :ok
    assert elem(result, 1).name == "https-token"
    assert elem(result, 1).version == "0.1.100"
    assert elem(result, 1).parameters |> map_size == 3
  end
end
