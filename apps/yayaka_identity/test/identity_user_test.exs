defmodule YayakaIdentity.IdentityUserTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaIdentity.IdentityUser

  test "valid changeset" do
    sender = %{host: "host1", service: :presentation}
    attribute1 = %{protocol: "yayaka", key: "name",
      value: %{name: "name1"}, sender: sender}
    attribute2 = %{protocol: "yayaka", key: "biography",
      value: %{text: "biography1"}, sender: sender}
    params = %{
      id: "user1",
      user_attributes: [attribute1, attribute2],
      sender: sender
    }
    changeset = IdentityUser.changeset(%IdentityUser{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "user1"
    assert get_change(changeset, :sender) == sender
    attributes = get_change(changeset, :user_attributes)
    assert length(attributes) == 2
    attribute = hd(attributes)
    assert get_change(attribute, :protocol) == "yayaka"
    assert get_change(attribute, :key) == "name"
    assert get_change(attribute, :value).name == "name1"
    assert get_change(attribute, :sender) == sender
  end

  test "invalid changeset" do
    sender = %{host: "host1", service: :presentation}
    attribute1 = %{protocol: "yayaka", key: "name",
      value: %{name: "name1"}, sender: sender}
    attribute2 = %{protocol: "yayaka", key: "invalid-type",
      value: %{}, sender: sender}
    params = %{
      id: "user1",
      user_attributes: [attribute1, attribute2],
      sender: sender
    }
    changeset = IdentityUser.changeset(%IdentityUser{}, params)
    refute changeset.valid?
  end
end
