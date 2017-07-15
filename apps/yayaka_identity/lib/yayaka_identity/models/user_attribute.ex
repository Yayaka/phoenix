defmodule YayakaIdentity.UserAttribute do
  use Ecto.Schema
  import Ecto.Changeset

  @user_attributes Application.get_env(:yayaka, :user_attributes)
  @user_attribute_types Application.get_env(:yayaka_identity, :user_attribute_types)
  |> Enum.map(fn {key, value} ->
    value = Enum.map(value, fn {key, value} ->
      {key, ExJsonSchema.Schema.resolve(value)}
    end) |> Enum.into(%{})
    {key, value}
  end)
  |> Enum.into(%{})

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
    |> validate_change(:value, fn :value, value ->
      protocol = get_field(changeset, :protocol)
      key = get_field(changeset, :key)
      schema = get_in(@user_attribute_types, [protocol, key])
      with false <- is_nil(schema),
           true <- ExJsonSchema.Validator.valid?(schema, value) do
        [] # No errors
      else
        _ ->
          [{:value, "is invalid"}]
      end
    end)
  end
end
