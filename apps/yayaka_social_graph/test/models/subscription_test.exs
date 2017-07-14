defmodule YayakaSocialGraph.SubscriptionTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.Subscription

  test "valid changeset" do
    {:ok, user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    } |> DB.Repo.insert
    {:ok, target_user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user2"
    } |> DB.Repo.insert
    sender = %{host: "host1", service: :social_graph}
    params = %{
      user_id: user.id,
      target_user_id: target_user.id,
      social_graph: %{host: "host1", service: :social_graph},
      sender: sender
    }
    changeset = Subscription.changeset(%Subscription{}, params)
    assert changeset.valid?
    assert get_change(changeset, :user_id) == user.id
    assert get_change(changeset, :target_user_id) == target_user.id
    assert get_change(changeset, :social_graph).service == :social_graph
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{
      user_id: 0,
      target_user_id: 1,
      social_graph: %{host: "host1", service: :presentation},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = Subscription.changeset(%Subscription{}, params)
    refute changeset.valid?
  end
end
