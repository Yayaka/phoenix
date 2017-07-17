defmodule Yayaka.UserTest do
  use ExUnit.Case

  test "cast" do
    user1 = Ecto.Type.cast(Yayaka.User,
                              %{host: "host1", id: "user1"})
    user2 = Ecto.Type.cast(Yayaka.User,
                              %{"host" => "host2", "id" => "user2"})
    assert user1 == {:ok, %{host: "host1", id: "user1"}}
    assert user2 == {:ok, %{host: "host2", id: "user2"}}
  end

  test "dump" do
    user1 = Ecto.Type.dump(Yayaka.User,
                              %{host: "host1", id: "user1"})
    assert user1 == {:ok, "[\"host1\",\"user1\"]"}
  end

  test "load" do
    user1 = Ecto.Type.load(Yayaka.User, "[\"host1\",\"user1\"]")
    assert user1 == {:ok, %{host: "host1", id: "user1"}}
  end
end
