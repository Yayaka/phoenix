defmodule YayakaRepository.ContentTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaRepository.Content

  test "valid changeset" do
    {:ok, user} = %Yayaka.User{
      identity: %{host: "host1", service: :identity},
      user_id: "user1"
    } |> DB.Repo.insert
    sender = %{host: "host1", service: :presentation}
    params = %{
      id: "id1",
      user_id: user.id,
      protocol: "yayaka",
      type: "plaintext",
      body: %{body: "text"},
      sender: sender
    }
    changeset = Content.changeset(%Content{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user_id) == user.id
    assert get_change(changeset, :protocol) == "yayaka"
    assert get_change(changeset, :type) == "plaintext"
    assert get_change(changeset, :body).body == "text"
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{
      id: "id1",
      user_id: 0,
      protocol: "yayaka",
      type: "invalid-type",
      body: %{},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = Content.changeset(%Content{}, params)
    refute changeset.valid?
  end
end
