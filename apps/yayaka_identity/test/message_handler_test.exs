defmodule YayakaIdentity.MessageHandlerTest do
  use ExUnit.Case
  require Logger
  alias YayakaIdentity.IdentityUser
  alias YayakaIdentity.AuthorizedService
  import Ecto.Query
  import YMP.TestMessageHandler, only: [request: 2, request: 3]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
  end

  @host YMP.get_host()
  @handler YayakaIdentity.MessageHandler

  def create_message(action, payload) do
    YMP.Message.new(@host,
                    "yayaka", "identity", action, payload,
                    "yayaka", "presentation")
  end

  def authorize(user) do
    authorization = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: @host, service: :presentation},
      sender: %{host: @host, service: :presentation}
    }
    DB.Repo.insert!(authorization)
  end

  def revoke_authorization(authorization) do
    DB.Repo.delete!(authorization)
  end

  test "create-user" do
    payload = %{
      "user-name" => "user1",
      "attributes" => [
        %{
          "protocol" => "yayaka",
          "key" => "name",
          "value" => %{"text" => "user1name"}
        },
      ]
    }
    message = create_message("create-user", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    user = DB.Repo.get(IdentityUser, body["user-id"])
    assert body["user-name"] == "user1"
    assert user.name == "user1"
    attributes = DB.Repo.all(Ecto.assoc(user, :user_attributes))
    assert attributes |> length == 1
    assert hd(attributes).value == %{"text" => "user1name"}
    # Same name
    payload = %{
      "user-name" => "user1",
      "attributes" => []
    }
    message = create_message("create-user", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    user = DB.Repo.get(IdentityUser, body["user-id"])
    assert body["user-name"] != "user1"
    assert user.name != "user1"
  end

  test "check-user-name-availability" do
    user = %IdentityUser{
      id: "aaa",
      name: "user1",
      sender: %{host: @host, service: :presentation}
    }
    DB.Repo.insert!(user)
    payload = %{
      "user-name" => "user1",
    }
    message = create_message("check-user-name-availability", payload)
    {:ok, answer} = request(@handler, message)
    refute answer["payload"]["body"]["availability"]
    payload = %{
      "user-name" => "user2",
    }
    message = create_message("check-user-name-availability", payload)
    {:ok, answer} = request(@handler, message)
    assert answer["payload"]["body"]["availability"]
  end

  test "update-user-name" do
    user = %IdentityUser{
      id: "aaa",
      name: "user1",
      sender: %{host: @host, service: :presentation}
    }
    DB.Repo.insert!(user)
    authorization = authorize(user)
    payload = %{
      "user-id" => "aaa",
      "user-name" => "user1"
    }
    message = create_message("update-user-name", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    assert body["user-name"] == "user1"
    payload = %{
      "user-id" => "aaa",
      "user-name" => "user2"
    }
    message = create_message("update-user-name", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    assert body["user-name"] == "user2"

    revoke_authorization(authorization)
    payload = %{
      "user-id" => "aaa",
      "user-name" => "user2"
    }
    message = create_message("update-user-name", payload)
    assert :timeout == request(@handler, message, true)
  end

  test "update-user-attributes" do
    sender = %{host: @host, service: :presentation}
    attribute1 = %{"protocol" => "yayaka", "key" => "name",
      "value" => %{"text" => "name1"}, "sender" => sender}
    attribute2 = %{"protocol" => "yayaka", "key" => "biography",
      "value" => %{"text" => "biography1"}, "sender" => sender}
    attribute3 = %{"protocol" => "yayaka", "key" => "primary-publisher-host",
      "value" => %{"host" => "host1"}, "sender" => sender}
    params = %{
      id: "user1",
      name: "name1",
      user_attributes: [attribute1, attribute2, attribute3],
      sender: sender
    }
    changeset = IdentityUser.changeset(%IdentityUser{}, params)
    user = DB.Repo.insert!(changeset) |> DB.Repo.preload([:user_attributes])
    authorization = authorize(user)
    attribute1 = %{"protocol" => "yayaka", "key" => "name",
      "value" => %{"text" => "name1"}, "sender" => sender}
    attribute2 = %{"protocol" => "yayaka", "key" => "biography",
      "value" => %{"text" => "biography2"}, "sender" => sender}
    attribute3 = %{"protocol" => "yayaka", "key" => "icon",
      "value" => %{"url" => "http://example.com/icon.png"}, "sender" => sender}
    attribute4 = %{"protocol" => "yayaka", "key" => "primary-publisher-host",
      "value" => nil}
    attributes = [attribute1, attribute2, attribute3, attribute4]
    payload = %{
      "user-id" => "user1",
      "attributes" => attributes
    }
    message = create_message("update-user-attributes", payload)
    {:ok, answer} = request(@handler, message)
    assert answer["payload"]["body"] == %{}
    user = DB.Repo.get(IdentityUser, user.id) |> DB.Repo.preload([:user_attributes])
    attributes = user.user_attributes
    assert attributes |> length == 3
    name = Enum.find(attributes, fn a -> a.key == "name" end)
    biography = Enum.find(attributes, fn a -> a.key == "biography" end)
    icon = Enum.find(attributes, fn a -> a.key == "icon" end)
    assert name.value == %{"text" => "name1"}
    assert biography.value == %{"text" => "biography2"}
    assert icon.value == %{"url" => "http://example.com/icon.png"}

    revoke_authorization(authorization)
    attribute1 = %{"protocol" => "yayaka", "key" => "name",
      "value" => %{"text" => "name1"}, "sender" => sender}
    attributes = [attribute1]
    payload = %{
      "user-id" => "user1",
      "attributes" => attributes
    }
    message = create_message("update-user-attributes", payload)
    assert :timeout == request(@handler, message, true)
  end

  test "fetch-user" do
    sender = %{host: "host1", service: :presentation}
    attribute1 = %{"protocol" => "yayaka", "key" => "name",
      "value" => %{"text" => "name1"}, "sender" => sender}
    attribute2 = %{"protocol" => "yayaka", "key" => "biography",
      "value" => %{"text" => "biography1"}, "sender" => sender}
    params = %{
      id: "user1",
      name: "name1",
      user_attributes: [attribute1, attribute2],
      sender: sender
    }
    changeset = IdentityUser.changeset(%IdentityUser{}, params)
    user = DB.Repo.insert!(changeset)
    service1 = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: "host1", service: :presentation},
      sender: %{host: "host1", service: :presentation}}
    service2 = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: "host2", service: :presentation},
      sender: %{host: "host1", service: :presentation}}
    service1 == DB.Repo.insert!(service1)
    service2 == DB.Repo.insert!(service2)
    payload = %{
      "user-id" => user.id
    }
    message = create_message("fetch-user", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    assert body["user-name"] == "name1"
    attributes = body["attributes"]
    authorized_services = body["authorized-services"]
    assert length(attributes) == 2
    attribute1 = Map.delete(attribute1, "sender")
                 |> Map.put("sender-host", sender.host)
    attribute2 = Map.delete(attribute2, "sender")
                 |> Map.put("sender-host", sender.host)
    assert attribute1 in attributes
    assert attribute2 in attributes
    assert length(authorized_services) == 2
    assert %{"host" => "host1",
      "service" => "presentation",
      "sender-host" => "host1"} in authorized_services
    assert %{"host" => "host2",
      "service" => "presentation",
      "sender-host" => "host1"} in authorized_services
  end

  test "fetch-user-by-name" do
    sender = %{host: "host1", service: :presentation}
    attribute1 = %{"protocol" => "yayaka", "key" => "name",
      "value" => %{"text" => "name1"}, "sender" => sender}
    attribute2 = %{"protocol" => "yayaka", "key" => "biography",
      "value" => %{"text" => "biography1"}, "sender" => sender}
    params = %{
      id: "user1",
      name: "name1",
      user_attributes: [attribute1, attribute2],
      sender: sender
    }
    changeset = IdentityUser.changeset(%IdentityUser{}, params)
    user = DB.Repo.insert!(changeset)
    service1 = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: "host1", service: :presentation},
      sender: %{host: "host1", service: :presentation}}
    service2 = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: "host2", service: :presentation},
      sender: %{host: "host1", service: :presentation}}
    service1 == DB.Repo.insert!(service1)
    service2 == DB.Repo.insert!(service2)
    payload = %{
      "user-name" => user.name
    }
    message = create_message("fetch-user-by-name", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    assert body["user-id"] == user.id
    attributes = body["attributes"]
    authorized_services = body["authorized-services"]
    assert length(attributes) == 2
    attribute1 = Map.delete(attribute1, "sender")
                 |> Map.put("sender-host", sender.host)
    attribute2 = Map.delete(attribute2, "sender")
                 |> Map.put("sender-host", sender.host)
    assert attribute1 in attributes
    assert attribute2 in attributes
    assert length(authorized_services) == 2
    assert %{"host" => "host1",
      "service" => "presentation",
      "sender-host" => "host1"} in authorized_services
    assert %{"host" => "host2",
      "service" => "presentation",
      "sender-host" => "host1"} in authorized_services
  end

  test "get-token" do
    user = %IdentityUser{
      id: "user1",
      name: "name1",
      sender: %{host: "host1", service: :presentation}
    }
    user = DB.Repo.insert!(user)
    authorization = authorize(user)
    payload = %{
      "user-id" => user.id,
      "presentation-host" => "host1"
    }
    message = create_message("get-token", payload)
    {:ok, answer} = request(@handler, message)
    body = answer["payload"]["body"]
    token = body["token"]
    {:ok, claims} = Guardian.decode_and_verify(token)
    assert {:ok, %{"host" => "host1"}} == Guardian.serializer.from_token(claims["sub"])
    assert body["expires"] > DateTime.utc_now |> DateTime.to_unix

    revoke_authorization(authorization)
    payload = %{
      "user-id" => user.id,
      "presentation-host" => "host1"
    }
    message = create_message("get-token", payload)
    assert :timeout == request(@handler, message, true)
  end

  test "authenticate-user" do
    user = %IdentityUser{
      id: "user1",
      name: "name1",
      sender: %{host: "host1", service: :presentation}
    }
    user = DB.Repo.insert!(user)
    query = from a in AuthorizedService,
      where: a.identity_user_id == ^user.id,
      where: a.service == ^%{host: @host, service: :presentation}

    resource = %{host: "aaaa"}
    {:ok, token, claims} = Guardian.encode_and_sign(resource)
    payload = %{
      "user-id" => user.id,
      "token" => token
    }
    message = create_message("authenticate-user", payload)
    assert :timeout == request(@handler, message, true)
    assert 0 == DB.Repo.aggregate(query, :count, :id)

    payload = %{
      "user-id" => user.id,
      "token" => "aaaa"
    }
    message = create_message("authenticate-user", payload)
    assert :timeout == request(@handler, message, true)
    assert 0 == DB.Repo.aggregate(query, :count, :id)

    resource = %{host: @host}
    {:ok, token, claims} = Guardian.encode_and_sign(resource)
    payload = %{
      "user-id" => user.id,
      "token" => token
    }
    message = create_message("authenticate-user", payload)
    {:ok, answer} = request(@handler, message)
    assert %{} == answer["payload"]["body"]
    assert 1 == DB.Repo.aggregate(query, :count, :id)
  end

  test "authorize-service" do
    user = %IdentityUser{
      id: "user1",
      name: "name1",
      sender: %{host: "host1", service: :presentation}
    }
    user = DB.Repo.insert!(user)
    payload = %{
      "user-id" => user.id,
      "host" => "host1",
      "service" => "presentation"
    }
    message = create_message("authorize-service", payload)
    assert :timeout == request(@handler, message, true)

    authorization = authorize(user)
    {:ok, answer} = request(@handler, message)
    payload = %{
      "user-id" => user.id,
      "host" => "host1",
      "service" => "repository"
    }
    message = create_message("authorize-service", payload)
    {:ok, answer} = request(@handler, message)
    assert %{} == answer["payload"]["body"]
    query = from a in AuthorizedService,
      where: a.identity_user_id == ^user.id,
      where: a.service == ^%{host: "host1", service: :repository}
    assert 1 == DB.Repo.aggregate(query, :count, :id)
  end

  test "revoke-service-authorization" do
    user = %IdentityUser{
      id: "user1",
      name: "name1",
      sender: %{host: "host1", service: :presentation}
    }
    user = DB.Repo.insert!(user)
    service1 = %AuthorizedService{
      identity_user_id: user.id,
      service: %{host: "host1", service: :repository},
      sender: %{host: "host1", service: :presentation}}
    service1 = DB.Repo.insert!(service1)
    query = from a in AuthorizedService,
      where: a.identity_user_id == ^user.id,
      where: a.service == ^%{host: "host1", service: :repository}
    payload = %{
      "user-id" => user.id,
      "host" => "host1",
      "service" => "repository"
    }
    message = create_message("revoke-service-authorization", payload)
    assert :timeout == request(@handler, message, true)
    assert 1 == DB.Repo.aggregate(query, :count, :id)

    authorization = authorize(user)
    {:ok, answer} = request(@handler, message)
    payload = %{
      "user-id" => user.id,
      "host" => "host1",
      "service" => "repository"
    }
    message = create_message("revoke-service-authorization", payload)
    {:ok, answer} = request(@handler, message)
    assert %{} == answer["payload"]["body"]
    assert 0 == DB.Repo.aggregate(query, :count, :id)
  end
end
