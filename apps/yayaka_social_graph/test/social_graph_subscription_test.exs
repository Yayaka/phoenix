defmodule YayakaSocialGraph.SocialGraphSubscriptionTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaSocialGraph.SocialGraphSubscription

  test "valid changeset" do
    sender = %{host: "host1", service: :social_graph}
    params = %{
      user_id: 0,
      target_user_id: 1,
      social_graph: %{host: "host1", service: :social_graph},
      sender: sender
    }
    changeset = SocialGraphSubscription.changeset(%SocialGraphSubscription{}, params)
    assert changeset.valid?
    assert get_change(changeset, :user_id) == 0
    assert get_change(changeset, :target_user_id) == 1
    assert get_change(changeset, :social_graph).service == :social_graph
    assert get_change(changeset, :sender) == sender
  end

  test "invalid changeset" do
    params = %{
      user_id: 0,
      target_user_id: 1,
      social_graph: %{host: "host1", service: :presentation},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = SocialGraphSubscription.changeset(%SocialGraphSubscription{}, params)
    refute changeset.valid?
  end
end
