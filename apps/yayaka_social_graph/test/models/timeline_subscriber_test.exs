defmodule YayakaSocialGraph.TimelineSubscriberTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.TimelineSubscriber

  test "valid changeset" do
    sender = %{host: "host1", service: :presentation}
    now = DateTime.utc_now() |> DateTime.to_unix()
    params = %{
      id: "id1",
      user: %{host: "host1", id: "user1"},
      presentation: %{host: "host1", service: :presentation},
      expires: now,
      sender: sender
    }
    changeset = TimelineSubscriber.changeset(%TimelineSubscriber{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user) == %{host: "host1", id: "user1"}
    assert get_change(changeset, :presentation).service == :presentation
    assert get_change(changeset, :expires) == now
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
