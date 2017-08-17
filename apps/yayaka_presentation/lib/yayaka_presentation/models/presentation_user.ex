defmodule YayakaPresentation.PresentationUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "presentation_users" do
    field :name, :string
    field :password_hash, :string

    timestamps()
  end

  @fields [:name, :password_hash]
  def changeset(provided_user, params) do
    provided_user
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:name)
  end
end
