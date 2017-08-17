defmodule YayakaPresentation.UserLinkTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaPresentation.UserLink

  test "valid changeset" do
    {:ok, presentation_user} = %YayakaPresentation.PresentationUser{
      name: "name1",
      password_hash: "abcd"
    } |> DB.Repo.insert
    user_link = %{
      presentation_user_id: presentation_user.id,
      user: %{host: "host1", id: "user1"}
    }
    changeset = UserLink.changeset(%UserLink{}, user_link)
    assert changeset.valid?
    assert get_change(changeset, :presentation_user_id) == presentation_user.id
    assert get_change(changeset, :user) == user_link.user
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    user_link = %{
    }
    changeset = UserLink.changeset(%UserLink{}, user_link)
    refute changeset.valid?
  end
end
