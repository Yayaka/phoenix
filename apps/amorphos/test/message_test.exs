defmodule Amorphos.MessageTest do
  use ExUnit.Case

  test "new" do
    message = Amorphos.Message.new("host1", "protocol1", "service1", "action1",
                              %{a: 1}, "protocol2", "service2")
    assert map_size(message) == 7
    assert message["id"] |> String.length >= 1
    assert message["host"] == "host1"
    assert message["protocol"] == "protocol1"
    assert message["service"] == "service1"
    assert message["action"] == "action1"
    assert message["payload"] == %{a: 1}
    assert map_size(message["sender"]) == 3
    assert message["sender"]["host"] == Amorphos.get_host()
    assert message["sender"]["protocol"] == "protocol2"
    assert message["sender"]["service"] == "service2"
  end

  test "new_answer" do
    message = Amorphos.Message.new(Amorphos.get_host(), "protocol1", "service1", "action1",
                              %{a: 1}, "protocol2", "service2")
    answer = Amorphos.Message.new_answer(message, %{b: 2})
    assert map_size(message) == 7
    assert answer["id"] |> String.length >= 1
    assert answer["id"] != message["id"]
    assert answer["reply-to"] == message["id"]
    assert answer["host"] == Amorphos.get_host()
    assert answer["protocol"] == "protocol2"
    assert answer["service"] == "service2"
    assert answer["action"] == "action1"
    assert answer["payload"] == %{b: 2}
    assert map_size(answer["sender"]) == 3
    assert answer["sender"]["host"] == Amorphos.get_host()
    assert answer["sender"]["protocol"] == "protocol1"
    assert answer["sender"]["service"] == "service1"
  end
end
