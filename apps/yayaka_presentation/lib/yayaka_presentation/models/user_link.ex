defmodule YayakaPresentation.UserLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "user_links" do
    belongs_to :presentation_user, YayakaPresentation.PresentationUser
    field :user, Yayaka.User

    timestamps()
  end

  @fields [:presentation_user_id, :user]
  def changeset(user_link, params) do
    user_link
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:user_id, name: :user_links_unique_index)
    |> foreign_key_constraint(:presentation_user_id)
  end
end
