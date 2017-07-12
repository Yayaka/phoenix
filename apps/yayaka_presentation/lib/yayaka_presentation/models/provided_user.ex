defmodule YayakaPresentation.ProvidedUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "provided_users" do
    field :provider, :string
    field :provided_id, :string

    timestamps()
  end

  @fields [:provider, :provided_id]
  def changeset(provided_user, params) do
    provided_user
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:provided_id, name: :provided_user_provider_provided_id_index)
  end
end
