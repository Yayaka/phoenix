defmodule YayakaPresentation.EventSubscriptionTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaPresentation.EventSubscription

  test "valid changeset" do
    {:ok, user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    } |> DB.Repo.insert
    event = %{id: "id1", user_id: user.id,
      social_graph: %{host: "host1", service: :social_graph}}
    changeset = EventSubscription.changeset(%EventSubscription{}, event)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user_id) == user.id
    assert get_change(changeset, :social_graph).service == :social_graph
  end

  test "invalid changeset" do
    event = %{user_id: 0,
      social_graph: %{host: "host1", service: :repository}}
    changeset = EventSubscription.changeset(%EventSubscription{}, event)
    refute changeset.valid?
  end
end
