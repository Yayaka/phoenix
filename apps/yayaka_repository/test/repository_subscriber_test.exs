defmodule YayakaRepository.RepositorySubscriberTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaRepository.RepositorySubscriber

  test "valid changeset" do
    sender = %{host: "host1", service: :social_graph}
    params = %{
      user_id: 0,
      social_graph: %{host: "host1", service: :social_graph},
      sender: sender
    }
    changeset = RepositorySubscriber.changeset(%RepositorySubscriber{}, params)
    assert changeset.valid?
    assert get_change(changeset, :user_id) == 0
    assert get_change(changeset, :social_graph).service == :social_graph
    assert get_change(changeset, :sender) == sender
  end

  test "invalid changeset" do
    params = %{
      user_id: 0,
      social_graph: %{host: "host1", service: :presentation},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = RepositorySubscriber.changeset(%RepositorySubscriber{}, params)
    refute changeset.valid?
  end
end
