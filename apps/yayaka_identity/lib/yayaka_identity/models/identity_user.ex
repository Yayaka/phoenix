defmodule YayakaIdentity.IdentityUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias YayakaIdentity.UserAttribute
  alias YayakaIdentity.AuthorizedService

  @primary_key {:id, :string, autogenerate: false}
  schema "identity_users" do
    field :name, :string
    field :sender, Yayaka.Service
    timestamps()

    has_many :user_attributes, UserAttribute
    has_many :authorized_services, AuthorizedService
  end

  @fields [:id, :name, :sender]
  def changeset(identity_user, params) do
    identity_user
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> cast_assoc(:user_attributes)
  end
end
