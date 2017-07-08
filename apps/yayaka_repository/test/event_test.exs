defmodule YayakaRepository.EventTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaRepository.Event

  test "valid changeset" do
    sender = %{host: "host1", service: :presentation}
    params = %{
      id: "id1",
      user_id: 0,
      protocol: "yayaka",
      type: "delete-content",
      payload: %{"content-id": "id0"},
      sender: sender
    }
    changeset = Event.changeset(%Event{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user_id) == 0
    assert get_change(changeset, :protocol) == "yayaka"
    assert get_change(changeset, :type) == "delete-content"
    assert get_change(changeset, :payload)."content-id" == "id0"
    assert get_change(changeset, :sender) == sender
  end

  test "invalid changeset" do
    params = %{
      id: "id1",
      user_id: 0,
      protocol: "yayaka",
      type: "invalid-type",
      payload: %{id: "id0"},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = Event.changeset(%Event{}, params)
    refute changeset.valid?
  end
end
