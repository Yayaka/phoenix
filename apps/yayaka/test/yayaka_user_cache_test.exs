defmodule Yayaka.YayakaUserCacheTest do
  use ExUnit.Case
  alias Yayaka.YayakaUserCache
  alias Yayaka.YayakaUser
  import Amorphos.TestMessageHandler, only: [with_mocks: 1, mock: 3]
  alias Yayaka.MessageHandler.Utils

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
    Cachex.clear(:yayaka_user)
    Cachex.clear(:yayaka_user_name)
    :ok
  end

  test "get_or_fetch with cache" do
    user = %{host: "host1", id: "id1"}
    cache = %YayakaUser{
      id: user.id,
      host: user.host,
      name: "name1",
      attributes: [],
      authorized_services: []
    }
    Cachex.set(:yayaka_user, user, cache)
    assert {:ok, cache} == YayakaUserCache.get_or_fetch(user)
  end

  test "get_or_fetch with no cache" do
    user = %{host: "host1", id: "id1"}
    cache = %YayakaUser{
      id: user.id,
      host: user.host,
      name: "name1",
      attributes: [],
      authorized_services: []
    }
    with_mocks do
      mock user.host, "fetch-user", fn message ->
        assert message["payload"]["user-id"] == user.id
        body = %{
          "user-name" => cache.name,
          "attributes" => cache.attributes,
          "authorized-services" => cache.authorized_services}
        answer = Utils.new_answer(message, body)
        Amorphos.MessageGateway.push(answer)
      end
      assert {:ok, cache} == YayakaUserCache.get_or_fetch(user)
      assert {:ok, cache} == Cachex.get(:yayaka_user, user)
      assert {:ok, user.id} == Cachex.get(:yayaka_user_name, %{host: user.host, name: cache.name})
    end
  end

  test "get_or_fetch_by_name with cache" do
    user = %{host: "host1", id: "id1"}
    cache = %YayakaUser{
      id: user.id,
      host: user.host,
      name: "name1",
      attributes: [],
      authorized_services: []
    }
    Cachex.set(:yayaka_user, user, cache)
    Cachex.set(:yayaka_user_name, %{host: user.host, name: cache.name}, user.id)
    assert {:ok, cache} == YayakaUserCache.get_or_fetch_by_name(user.host, cache.name)
  end

  test "get_or_fetch_by_name with cache if the name is changed" do
    user = %{host: "host1", id: "id1"}
    old_name = "old_name1"
    cache = %YayakaUser{
      id: user.id,
      host: user.host,
      name: "name1",
      attributes: [],
      authorized_services: []
    }
    Cachex.set(:yayaka_user, user, cache)
    Cachex.set(:yayaka_user_name, %{host: user.host, name: old_name}, user.id)
    assert :error == YayakaUserCache.get_or_fetch_by_name(user.host, old_name)
    assert {:missing, nil} == Cachex.get(:yayaka_user_name, %{host: user.host, name: old_name})
  end

  test "get_or_fetch_by_name with no cache" do
    user = %{host: "host1", id: "id1"}
    cache = %YayakaUser{
      id: user.id,
      host: user.host,
      name: "name1",
      attributes: [],
      authorized_services: []
    }
    with_mocks do
      mock user.host, "fetch-user-by-name", fn message ->
        assert message["payload"]["user-name"] == cache.name
        body = %{
          "user-id" => user.id,
          "attributes" => cache.attributes,
          "authorized-services" => cache.authorized_services}
        answer = Utils.new_answer(message, body)
        Amorphos.MessageGateway.push(answer)
      end
      assert {:ok, cache} == YayakaUserCache.get_or_fetch_by_name(user.host, cache.name)
      assert {:ok, cache} == Cachex.get(:yayaka_user, user)
      assert {:ok, user.id} == Cachex.get(:yayaka_user_name, %{host: user.host, name: cache.name})
    end
  end

  test "delete" do
    user1 = %{host: "host1", id: "id1"}
    cache1 = %YayakaUser{
      id: user1.id,
      host: user1.host,
      name: "name1",
      attributes: [],
      authorized_services: []
    }
    user2 = %{host: "host2", id: "id2"}
    cache2 = %YayakaUser{
      id: user2.id,
      host: user2.host,
      name: "name2",
      attributes: [],
      authorized_services: []
    }
    Cachex.set(:yayaka_user, user1, cache1)
    Cachex.set(:yayaka_user, user2, cache2)
    YayakaUserCache.delete(user2)
    assert {:ok, cache1} == Cachex.get(:yayaka_user, user1)
    assert {:missing, nil} == Cachex.get(:yayaka_user, user2)
  end
end
