defmodule YayakaPresentation.ProvidedUserTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaPresentation.ProvidedUser

  test "valid changeset" do
    provided_user = %{
      provider: "provider1",
      provided_id: "id1"
    }
    changeset = ProvidedUser.changeset(%ProvidedUser{}, provided_user)
    assert changeset.valid?
    assert get_change(changeset, :provider) == "provider1"
    assert get_change(changeset, :provided_id) == "id1"
  end

  test "invalid changeset" do
    provided_user = %{
    }
    changeset = ProvidedUser.changeset(%ProvidedUser{}, provided_user)
    refute changeset.valid?
  end
end

