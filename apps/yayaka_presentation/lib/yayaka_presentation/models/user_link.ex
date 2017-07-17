defmodule YayakaPresentation.UserLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "user_links" do
    belongs_to :provided_user, YayakaPresentation.ProvidedUser
    field :user, Yayaka.User

    timestamps()
  end

  @fields [:provided_user_id, :user]
  def changeset(user_link, params) do
    user_link
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:user_id, name: :user_links_unique_index)
    |> foreign_key_constraint(:provided_user_id)
  end
end
