defmodule Yayaka.UserTest do
  use ExUnit.Case

  test "valid changeset" do
    user1 = %{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    }
    changeset = Yayaka.User.changeset(%Yayaka.User{}, user1)
    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :identity).service == :identity
    assert Ecto.Changeset.get_change(changeset, :user_id) == "user1"
  end

  test "invalid changeset" do
    user1 = %{
      identity: %{host: "host1", service: :repository},
      user_id: "user1"
    }
    changeset = Yayaka.User.changeset(%Yayaka.User{}, user1)
    refute changeset.valid?
  end
end
