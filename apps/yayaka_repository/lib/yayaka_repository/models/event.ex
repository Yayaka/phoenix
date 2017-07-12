defmodule YayakaRepository.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "events" do
    belongs_to :user, Yayaka.User
    field :protocol, :string
    field :type, :string
    field :body, :map

    field :sender, Yayaka.Service
    timestamps()
  end

  @required_fields [:id, :user_id, :protocol, :type, :body, :sender]
  def changeset(event, params) do
    event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> Yayaka.EventType.validate_event_type()
    |> foreign_key_constraint(:user_id)
  end
end
