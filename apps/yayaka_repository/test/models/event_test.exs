defmodule YayakaRepository.EventTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaRepository.Event

  test "valid changeset" do
    {:ok, user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    } |> DB.Repo.insert
    sender = %{host: "host1", service: :presentation}
    params = %{
      id: "id1",
      user_id: user.id,
      protocol: "yayaka",
      type: "delete-content",
      body: %{"content-id": "id0"},
      sender: sender
    }
    changeset = Event.changeset(%Event{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user_id) == user.id
    assert get_change(changeset, :protocol) == "yayaka"
    assert get_change(changeset, :type) == "delete-content"
    assert get_change(changeset, :body)."content-id" == "id0"
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{
      id: "id1",
      user_id: 0,
      protocol: "yayaka",
      type: "invalid-type",
      body: %{id: "id0"},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = Event.changeset(%Event{}, params)
    refute changeset.valid?
  end
end
