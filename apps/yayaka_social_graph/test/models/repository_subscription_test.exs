defmodule YayakaSocialGraph.RepositorySubscriptionTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.RepositorySubscription

  test "valid changeset" do
    {:ok, user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    } |> DB.Repo.insert
    params = %{
      user_id: user.id,
      repository: %{host: "host1", service: :repository},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = RepositorySubscription.changeset(%RepositorySubscription{}, params)
    assert changeset.valid?
    assert get_change(changeset, :user_id) == user.id
    assert get_change(changeset, :repository).service == :repository
    assert get_change(changeset, :sender).service == :presentation
    assert match? {:ok, _}, DB.Repo.insert(changeset)
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
