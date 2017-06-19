defmodule YayakaRepository.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "events" do
    belongs_to :user, Yayaka.User
    field :protocol, :string
    field :type, :string
    field :payload, :map
    field :deleted, :boolean, default: false

    field :sender, Yayaka.Service
    timestamps()
  end

  @required_fields [:id, :user_id, :protocol, :type, :payload, :sender]
  @fields [:deleted] ++ @required_fields
  def changeset(event, params) do
    event
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> Yayaka.EventType.validate_event_type()
    |> foreign_key_constraint(:user_id)
  end
end
