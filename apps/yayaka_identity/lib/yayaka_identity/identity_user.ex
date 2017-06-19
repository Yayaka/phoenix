defmodule YayakaIdentity.IdentityUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "identity_users" do
    field :sender, Yayaka.Service
    timestamps()

    has_many :user_attributes, YayakaIdentity.UserAttribute
  end

  @fields [:id, :sender]
  def changeset(identity_user, params) do
    identity_user
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> cast_assoc(:user_attributes)
  end
end
