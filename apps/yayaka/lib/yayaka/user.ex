defmodule Yayaka.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :identity, Yayaka.Service
    field :user_id, :string

    timestamps()
  end

  @fields [:identity, :user_id]
  def changeset(user, params) do
    user
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:id, name: :users_host_user_id_index)
    |> Yayaka.Service.validate_service(:identity, :identity)
  end
end
