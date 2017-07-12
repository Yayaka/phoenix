defmodule YMP.HostInformation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:host, :string, auto_generate: false}
  schema "host_informations" do
    field :ymp_version, :string
    embeds_many :connection_protocols, ConnectionProtocol do
      field :name, :string
      field :version, :string
      field :parameters, :map
    end
    embeds_many :service_protocols, ServiceProtocol do
      field :name, :string
      field :version, :string
      field :services, {:array, :string}
      field :parameters, :map
    end

    timestamps()
  end

  @fields [:host, :ymp_version]
  def changeset(host_information, params) do
    host_information
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> cast_embed(:connection_protocols, with: &connection_protocol_changeset/2)
    |> cast_embed(:service_protocols, with: &service_protocol_changeset/2)
  end

  @connection_protocol_fields [:name, :version, :parameters]
  def connection_protocol_changeset(connection_protocol, params) do
    connection_protocol
    |> cast(params, @connection_protocol_fields)
    |> validate_required(@connection_protocol_fields)
  end

  @service_protocol_fields [:name, :version, :services, :parameters]
  def service_protocol_changeset(service_protocol, params) do
    service_protocol
    |> cast(params, @service_protocol_fields)
    |> validate_required(@service_protocol_fields)
  end
end
