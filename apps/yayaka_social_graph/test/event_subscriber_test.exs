defmodule YayakaSocialGraph.EventSubscriberTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaSocialGraph.EventSubscriber

  test "valid changeset" do
    matcher1 = %{
      users: [%{user_id: 0}, %{user_id: 1}],
      types: [%{protocol: "yayaka", type: "post"},
              %{protocol: "yayaka", type: "repost"}]}
    matcher2 = %{
      users: [%{user_id: 2}],
      types: [%{protocol: "yayaka", type: "post"}]}
    sender = %{host: "host1", service: :presentation}
    params = %{
      id: "id1",
      presentation: %{host: "host1", service: :presentation},
      matchers: [matcher1, matcher2],
      sender: sender
    }
    changeset = EventSubscriber.changeset(%EventSubscriber{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :presentation).service == :presentation
    assert get_change(changeset, :sender) == sender
    matchers = get_change(changeset, :matchers)
    assert length(matchers) == 2
    matcher = hd(matchers)
    users = get_change(matcher, :users)
    types = get_change(matcher, :types)
    assert length(users) == 2
    assert length(types) == 2
    user = hd(users)
    type = hd(types)
    assert get_change(user, :user_id) == 0
    assert get_change(type, :protocol) == "yayaka"
    assert get_change(type, :type) == "post"
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
    changeset = EventSubscriber.changeset(%EventSubscriber{}, params)
    refute changeset.valid?
  end
end
