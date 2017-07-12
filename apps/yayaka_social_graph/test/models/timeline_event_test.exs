defmodule YayakaSocialGraph.TimelineEventTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.TimelineEvent

  test "valid changeset" do
    {:ok, user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    } |> DB.Repo.insert
    {:ok, event} = %YayakaSocialGraph.Event{
      social_graph: %{host: "host1", service: :social_graph},
      event_id: "event1",
      event: %{a: 1},
      sender: %{host: "host2", service: :social_graph}
    } |> DB.Repo.insert
    params = %{
      user_id: user.id,
      event_id: event.id
    }
    changeset = TimelineEvent.changeset(%TimelineEvent{}, params)
    assert changeset.valid?
    assert get_change(changeset, :user_id) == user.id
    assert get_change(changeset, :event_id) == event.id
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{
    }
    changeset = TimelineEvent.changeset(%TimelineEvent{}, params)
    refute changeset.valid?
  end
end
