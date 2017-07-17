defmodule YayakaSocialGraph.TimelineSubscriberTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.TimelineSubscriber

  test "valid changeset" do
    sender = %{host: "host1", service: :presentation}
    params = %{
      id: "id1",
      user: %{host: "host1", id: "user1"},
      presentation: %{host: "host1", service: :presentation},
      sender: sender
    }
    changeset = TimelineSubscriber.changeset(%TimelineSubscriber{}, params)
    IO.inspect(changeset)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user) == %{host: "host1", id: "user1"}
    assert get_change(changeset, :presentation).service == :presentation
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{
      id: "id1",
      user: %{host: "host1", id: "user1"},
      presentation: %{host: "host1", service: :presentation}
    }
    changeset = TimelineSubscriber.changeset(%TimelineSubscriber{}, params)
    refute changeset.valid?
  end
end
