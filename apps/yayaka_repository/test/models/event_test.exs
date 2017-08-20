defmodule YayakaRepository.EventTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaRepository.Event

  test "valid changeset" do
    sender = %{host: "host1", service: "presentation"}
    params = %{
      id: "id1",
      user: %{host: "host1", id: "user1"},
      protocol: "yayaka",
      type: "delete-post",
      body: %{"event-id" => "id0"},
      sender: sender
    }
    changeset = Event.changeset(%Event{}, params)
    assert changeset.valid?
    assert get_change(changeset, :id) == "id1"
    assert get_change(changeset, :user) == %{host: "host1", id: "user1"}
    assert get_change(changeset, :protocol) == "yayaka"
    assert get_change(changeset, :type) == "delete-post"
    assert get_change(changeset, :body)["event-id"] == "id0"
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{
      id: "id1",
      user: %{host: "host1", id: "user1"},
      protocol: "yayaka",
      type: "invalid-type",
      body: %{id: "id0"},
      sender: %{host: "host1", service: :presentation}
    }
    changeset = Event.changeset(%Event{}, params)
    refute changeset.valid?
  end

  defp wrap_body(protocol, type, body) do
    %{
      id: "id1",
      user: %{host: "host1", id: "user1"},
      protocol: protocol,
      type: type,
      body: body,
      sender: %{host: "host1", service: :presentation}
    }
  end
  defp test_body(protocol, type, valid, invalid) do
    valid = wrap_body(protocol, type, valid)
    invalid = wrap_body(protocol, type, invalid)
    assert Event.changeset(%Event{}, valid).valid?
    refute Event.changeset(%Event{}, invalid).valid?
  end

  test "yayaka post" do
    valid = %{
      "contents" => [
        %{"protocol" => "yayaka",
          "type" => "plaintext",
        "body" => %{"text" => "aaa"}}]}
    invalid = %{
      "contents" => [
        %{"protocol" => "yayaka",
          "type" => "unknown",
        "body" => %{"text" => "aaa"}}]}
    test_body("yayaka", "post", valid, invalid)
  end

  test "yayaka repost" do
    valid = %{
      "repository-host" => "host1",
      "event-id" => "0000"}
    invalid = %{
      "repository-host" => "host1",
      "event-id" => 0}
    test_body("yayaka", "repost", valid, invalid)
  end

  test "yayaka reply" do
    valid = %{
      "repository-host" => "host1",
      "event-id" => "0000",
      "contents" => [
        %{"protocol" => "yayaka",
          "type" => "plaintext",
        "body" => %{"text" => "aaa"}}]}
    invalid = %{
      "repository-host" => "host1",
      "event-id" => "0000",
      "contents" => [
        %{"protocol" => "yayaka",
          "type" => "unknown",
        "body" => %{"text" => "aaa"}}]}
    test_body("yayaka", "reply", valid, invalid)
  end

  test "yayaka quote" do
    valid = %{
      "repository-host" => "host1",
      "event-id" => "0000",
      "contents" => [
        %{"protocol" => "yayaka",
          "type" => "plaintext",
        "body" => %{"text" => "aaa"}}]}
    invalid = %{
      "repository-host" => "host1",
      "event-id" => "0000",
      "contents" => [
        %{"protocol" => "yayaka",
          "type" => "unknown",
        "body" => %{"text" => "aaa"}}]}
    test_body("yayaka", "quote", valid, invalid)
  end

  test "yayaka follow" do
    valid = %{
      "social-graph-host" => "host1",
      "target-identity-host" => "host2",
      "target-user-id" => "user1",
      "target-social-graph-host" => "host3"}
    invalid = %{
      "social-graph-host" => "host1",
      "target-identity-host" => "host2",
      "target-user-id" => 0,
      "target-social-graph-host" => "host3"}
    test_body("yayaka", "follow", valid, invalid)
  end

  test "yayaka delete-post" do
    valid = %{"event-id" => "0000"}
    invalid = %{"event-id" => 0}
    test_body("yayaka", "delete-post", valid, invalid)
  end

  test "yayaka update-post" do
    valid = %{
      "event-id" => "0000",
      "body" => %{
        "title" => "text",
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}]}}
    invalid = %{
      "event-id" => "0000",
      "body" => %{
        "title" => 0,
        "contents" => [
          %{"protocol" => "yayaka",
            "type" => "plaintext",
            "body" => %{"text" => "aaa"}}]}}
    test_body("yayaka", "update-post", valid, invalid)
  end
end
