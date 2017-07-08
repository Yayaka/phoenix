defmodule YayakaRepository.ContentTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaRepository.Content

  test "valid changeset" do
    sender = %{host: "host1", service: :presentation}
    params = %{
      id: "id1",
      user_id: 0,
      protocol: "yayaka",
      type: "plaintext",
      payload: %{body: "text"},
      sender: sender
    }
    changeset = Content.changeset(%Content{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user_id) == 0
    assert get_change(changeset, :protocol) == "yayaka"
    assert get_change(changeset, :type) == "plaintext"
    assert get_change(changeset, :payload).body == "text"
    assert get_change(changeset, :sender) == sender
  end

  test "invalid changeset" do
    params = %{
      id: "id1",
      user_id: 0,
      protocol: "yayaka",
      type: "invalid-type",
      payload: %{},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = Content.changeset(%Content{}, params)
    refute changeset.valid?
  end
end
