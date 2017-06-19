defmodule YayakaPresentation.UserLinkTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaPresentation.UserLink

  test "valid changeset" do
    user_link = %{
      provided_user_id: 0,
      user_id: 1
    }
    changeset = UserLink.changeset(%UserLink{}, user_link)
    assert changeset.valid?
    assert get_change(changeset, :provided_user_id) == 0
    assert get_change(changeset, :user_id) == 1
  end

  test "invalid changeset" do
    user_link = %{
    }
    changeset = UserLink.changeset(%UserLink{}, user_link)
    refute changeset.valid?
  end
end
