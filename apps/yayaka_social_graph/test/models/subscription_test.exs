defmodule YayakaSocialGraph.SubscriptionTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.Subscription

  test "valid changeset" do
    sender = %{host: "host1", service: "social-graph"}
    params = %{
      user: %{host: "host1", id: "user1"},
      target_user: %{host: "host1", id: "user2"},
      social_graph: %{host: "host1", service: :social_graph},
      sender: sender
    }
    changeset = Subscription.changeset(%Subscription{}, params)
    assert changeset.valid?
    assert get_change(changeset, :user) == %{host: "host1", id: "user1"}
    assert get_change(changeset, :target_user) == %{host: "host1", id: "user2"}
    assert get_change(changeset, :social_graph).service == "social-graph"
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{
      user: %{host: "host1", id: "user1"},
      target_user: %{host: "host1", id: "user2"},
      social_graph: %{host: "host1", service: :presentation},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = Subscription.changeset(%Subscription{}, params)
    refute changeset.valid?
  end
end
