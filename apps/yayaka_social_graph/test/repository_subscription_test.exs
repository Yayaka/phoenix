defmodule YayakaSocialGraph.RepositorySubscriptionTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaSocialGraph.RepositorySubscription

  test "valid changeset" do
    params = %{
      user_id: 0,
      repository: %{host: "host1", service: :repository},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = RepositorySubscription.changeset(%RepositorySubscription{}, params)
    assert changeset.valid?
    assert get_change(changeset, :user_id) == 0
    assert get_change(changeset, :repository).service == :repository
    assert get_change(changeset, :sender).service == :presentation
  end

  test "invalid changeset" do
    params = %{
      user_id: 0,
      repository: %{host: "host1", service: :presentation},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = RepositorySubscription.changeset(%RepositorySubscription{}, params)
    refute changeset.valid?
  end
end
