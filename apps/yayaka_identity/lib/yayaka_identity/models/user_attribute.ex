defmodule YayakaIdentity.UserAttribute do
  use Ecto.Schema
  import Ecto.Changeset

  @user_attributes Application.get_env(:yayaka, :user_attributes)

  schema "user_attributes" do
    belongs_to :identity_user, YayakaIdentity.IdentityUser, type: :string
    field :protocol, :string
    field :key, :string
    field :value, :map

    field :sender, Yayaka.Service
    timestamps()
  end

  @required_fields [:protocol, :key, :value, :sender]
  @fields [:identity_user_id] ++ @required_fields
  def changeset(user_attribute, params) do
    changeset = user_attribute
                |> cast(params, @fields)
                |> validate_required(@required_fields)
                |> unique_constraint(:key, name: :user_attributes_unique_index)
    validate_change(changeset, :key, fn :key, type ->
      protocol = get_change(changeset, :protocol)
      case Map.get(@user_attributes, protocol) do
        types when not is_nil(types) ->
          if type in types do
            [] # No errors
          else
            [{:key, "is invalid"}]
          end
        _ -> [{:protocol, "is invalid"}]
      end
    end)
  end
end
