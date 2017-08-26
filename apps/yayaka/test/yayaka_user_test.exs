defmodule Yayaka.YayakaUserTest do
  use ExUnit.Case
  alias Yayaka.YayakaUser

  test "authorizes?" do
    yayaka_user = %{
      host: "host1",
      id: "id1",
      name: "name1",
      attributes: [],
      authorized_services: [
        %{"host" => "host1",
          "service" => "social-graph",
          "sender-host" => "host2"}]}
    assert YayakaUser.authorizes?(yayaka_user,
                                  %{host: "host1", service: :social_graph})
    assert YayakaUser.authorizes?(yayaka_user,
                                  %{host: "host1", service: "social-graph"})
    refute YayakaUser.authorizes?(yayaka_user,
                                  %{host: "host1", service: :repository})
    refute YayakaUser.authorizes?(yayaka_user,
                                  %{host: "host2", service: :social_graph})
  end

  test "get_attribute" do
    yayaka_user = %{
      host: "host1",
      id: "id1",
      name: "name1",
      attributes: [
        %{"protocol" => "protocol1",
          "key" => "key1",
          "value" => "value1",
          "sender-host" => "host2"}],
      authorized_services: []}
    attribute = YayakaUser.get_attribute(yayaka_user, "protocol1", "key1")
    assert attribute["key"] == "key1"
    assert attribute["protocol"] == "protocol1"
    assert attribute["value"] == "value1"
    assert attribute["sender-host"] == "host2"
  end
end
