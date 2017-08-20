defmodule YayakaSocialGraph.EventTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.Event

  test "valid changeset" do
    sender = %{host: "host1", service: "presentation"}
    params = %{
      repository: %{host: "host2", service: :repository},
      event_id: "a",
      event: %{a: 1},
      sender: sender
    }
    changeset = Event.changeset(%Event{}, params)
    assert changeset.valid?
    assert get_change(changeset, :event) == %{a: 1}
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    sender = %{host: "host1", service: :presentation}
    params = %{
      repository: %{host: "host2", service: :presentation},
      event_id: "a",
      event: %{a: 1},
      sender: sender
    }
    changeset = Event.changeset(%Event{}, params)
    refute changeset.valid?
  end
end
