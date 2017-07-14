defmodule YayakaSocialGraph.TimelineSubscriberTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaSocialGraph.TimelineSubscriber

  test "valid changeset" do
    {:ok, user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    } |> DB.Repo.insert
    sender = %{host: "host1", service: :presentation}
    params = %{
      id: "id1",
      identity: %{host: "host1", service: :identity},
      user_id: user.id,
      presentation: %{host: "host1", service: :presentation},
      sender: sender
    }
    changeset = TimelineSubscriber.changeset(%TimelineSubscriber{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :identity).service == :identity
    assert get_change(changeset, :user_id) == user.id
    assert get_change(changeset, :presentation).service == :presentation
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    matcher1 = %{
      users: [%{user_id: 0}],
      types: [%{protocol: "yayaka", type: "post"}]}
    params = %{
      id: "id1",
      presentation: %{host: "host1", service: :social_graph},
      matchers: [matcher1],
      sender: %{host: "host1", service: :presentation}
    }
    changeset = TimelineSubscriber.changeset(%TimelineSubscriber{}, params)
    refute changeset.valid?
  end
end
