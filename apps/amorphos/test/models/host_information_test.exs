defmodule Amorphos.HostInformationTest do
  use DB.DataCase
  import Ecto.Changeset

  test "valid changeset" do
    connection_protocols = [%{
      name: "https-token",
      version: "1.0.0",
      parameters: %{}}]
    service_protocols = [%{
      name: "yayaka",
      version: "1.0.0",
      services: ["presentation"],
      parameters: %{}}]
    params = %{
      host: "host1",
      amorphos_version: "1.0.0",
      connection_protocols: connection_protocols,
      service_protocols: service_protocols
    }
    changeset = Amorphos.HostInformation.changeset(%Amorphos.HostInformation{}, params)
    assert changeset.valid?
    assert get_change(changeset, :host) == "host1"
    assert get_change(changeset, :amorphos_version) == "1.0.0"
    connection_protocols = get_change(changeset, :connection_protocols)
    assert length(connection_protocols) == 1
    connection_protocol = hd(connection_protocols)
    assert get_change(connection_protocol, :name) == "https-token"
    assert get_change(connection_protocol, :version) == "1.0.0"
    assert get_change(connection_protocol, :parameters) == %{}
    service_protocols = get_change(changeset, :service_protocols)
    assert length(service_protocols) == 1
    service_protocol = hd(service_protocols)
    assert get_change(service_protocol, :name) == "yayaka"
    assert get_change(service_protocol, :version) == "1.0.0"
    assert get_change(service_protocol, :services) == ["presentation"]
    assert get_change(service_protocol, :parameters) == %{}
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    connection_protocols = [%{
      name: "https-token",
      version: "1.0.0",
      parameters: %{}}]
    service_protocols = [%{
      name: "yayaka",
      version: "1.0.0",
      services: ["presentation"],
      parameters: %{}}]
    params = %{
      host: "host1",
      connection_protocols: connection_protocols,
      service_protocols: service_protocols
    }
    changeset = Amorphos.HostInformation.changeset(%Amorphos.HostInformation{}, params)
    refute changeset.valid?
  end
end
