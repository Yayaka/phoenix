defmodule YayakaIdentity.AuthorizedService do
  use Ecto.Schema
  import Ecto.Changeset

  schema "authorized_services" do
    belongs_to :identity_user, YayakaIdentity.IdentityUser, type: :string
    field :service, Yayaka.Service

    field :sender, Yayaka.Service
    timestamps()
  end

  @fields [:identity_user_id, :service, :sender]
  def changeset(authorized_service, params) do
    authorized_service
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:service, name: :authorized_services_unique_index)
    |> foreign_key_constraint(:identity_user_id)
  end
end
