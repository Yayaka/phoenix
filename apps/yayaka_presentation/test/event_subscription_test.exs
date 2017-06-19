defmodule YayakaPresentation.EventSubscriptionTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaPresentation.EventSubscription

  test "valid changeset" do
    event = %{id: "id1", user_id: 0,
      social_graph: %{host: "host1", service: :social_graph}}
    changeset = EventSubscription.changeset(%EventSubscription{}, event)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user_id) == 0
    assert get_change(changeset, :social_graph).service == :social_graph
  end

  test "invalid changeset" do
    event = %{user_id: 0,
      social_graph: %{host: "host1", service: :repository}}
    changeset = EventSubscription.changeset(%EventSubscription{}, event)
    refute changeset.valid?
  end
end
