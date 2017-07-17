defmodule YayakaPresentation.UserLinkTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaPresentation.UserLink

  test "valid changeset" do
    {:ok, provided_user} = %YayakaPresentation.ProvidedUser{
      provider: "provider1",
      provided_id: "id1"
    } |> DB.Repo.insert
    user_link = %{
      provided_user_id: provided_user.id,
      user: %{host: "host1", id: "user1"}
    }
    changeset = UserLink.changeset(%UserLink{}, user_link)
    assert changeset.valid?
    assert get_change(changeset, :provided_user_id) == provided_user.id
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
