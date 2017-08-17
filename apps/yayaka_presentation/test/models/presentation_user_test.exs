defmodule YayakaPresentation.PresentationUserTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaPresentation.PresentationUser

  test "valid changeset" do
    provided_user = %{
      name: "name1",
      password_hash: "abcd"
    }
    changeset = PresentationUser.changeset(%PresentationUser{}, provided_user)
    assert changeset.valid?
    assert get_change(changeset, :name) == "name1"
    assert get_change(changeset, :password_hash) == "abcd"
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    provided_user = %{
    }
    changeset = PresentationUser.changeset(%PresentationUser{}, provided_user)
    refute changeset.valid?
  end
end

