defmodule YayakaPresentation.TimelineSubscriptionTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaPresentation.TimelineSubscription

  test "valid changeset" do
    expires = DateTime.utc_now() |> DateTime.to_unix() |> Kernel.+(1000)
    event = %{id: "id1", user: %{host: "host1", id: "user1"},
      social_graph: %{host: "host1", service: :social_graph},
      expires: expires}
    changeset = TimelineSubscription.changeset(%TimelineSubscription{}, event)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user) == %{host: "host1", id: "user1"}
    assert get_change(changeset, :expires) == expires
    assert get_change(changeset, :social_graph).service == "social-graph"
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    event = %{user: %{host: "host1", id: "user1"},
      social_graph: %{host: "host1", service: :repository}}
    changeset = TimelineSubscription.changeset(%TimelineSubscription{}, event)
    refute changeset.valid?
  end
end
