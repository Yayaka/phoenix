defmodule YayakaPresentation.UserTest do
  use ExUnit.Case
  import YMP.TestMessageHandler, only: [with_mocks: 1, mock: 3]
  alias Yayaka.MessageHandler.Utils
  alias YayakaPresentation.User
  alias YayakaPresentation.PresentationUser
  alias YayakaPresentation.UserLink
  import Comeonin.Bcrypt, only: [hashpwsalt: 1, checkpw: 2]
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
  end

  test "sign_up" do
    user_name = "name1"
    user_password = "password1"
    {:ok, user} = User.sign_up(user_name, user_password)
    query = from u in PresentationUser,
      where: u.name == ^user_name
    assert user == DB.Repo.one!(query)
    assert checkpw(user_password, user.password_hash)
  end

  test "sign_in with correct password" do
    user_name = "name1"
    user_password = "password1"
    presentation_user = %PresentationUser{
      name: user_name,
      password_hash: hashpwsalt(user_password)
    } |> DB.Repo.insert!()
    assert {:ok, presentation_user} = User.sign_in(user_name, user_password)
  end

  test "sign_in with wrong password" do
    user_name = "name1"
    user_password = "password1"
    %PresentationUser{
      name: user_name,
      password_hash: hashpwsalt(user_password)
    } |> DB.Repo.insert!()
    assert :error = User.sign_in(user_name, "wrong_password")
  end

  test "get_user_links" do
    user_name = "name1"
    user_password = "password1"
    presentation_user = %PresentationUser{
      name: user_name,
      password_hash: hashpwsalt(user_password)
    } |> DB.Repo.insert!()
    user1 = %{host: "host1", id: "id1"}
    user2 = %{host: "host2", id: "id2"}
    user_link1 = %UserLink{
      presentation_user_id: presentation_user.id,
      user: user1} |> DB.Repo.insert!()
    user_link2 = %UserLink{
      presentation_user_id: presentation_user.id,
      user: user2} |> DB.Repo.insert!()
    list = User.get_user_links(presentation_user)
    assert user_link1 in list
    assert user_link2 in list
  end

  test "linked?" do
    user_name1 = "name1"
    user_password1 = "password1"
    user_name2 = "name2"
    user_password2 = "password2"
    presentation_user1 = %PresentationUser{
      name: user_name1,
      password_hash: hashpwsalt(user_password2)
    } |> DB.Repo.insert!()
    presentation_user2 = %PresentationUser{
      name: user_name2,
      password_hash: hashpwsalt(user_password2)
    } |> DB.Repo.insert!()
    user1 = %{host: "host1", id: "id1"}
    user2 = %{host: "host2", id: "id2"}
    user_link1 = %UserLink{
      presentation_user_id: presentation_user1.id,
      user: user1} |> DB.Repo.insert!()
    user_link2 = %UserLink{
      presentation_user_id: presentation_user2.id,
      user: user2} |> DB.Repo.insert!()
    assert User.linked?(presentation_user1, user1)
    assert User.linked?(presentation_user2, user2)
    refute User.linked?(presentation_user1, user2)
    refute User.linked?(presentation_user2, user1)
  end

  test "create" do
    presentation_user = %PresentationUser{
      name: "name1",
      password_hash: hashpwsalt("password1")
    } |> DB.Repo.insert!()
    identity_host = "host1"
    user_name = "name2"
    attributes = [
      %{"protocol" => "yayaka",
        "type" => "name",
        "value" => %{"text" => "Name 2"}}]
    created_user_id = "create_id"
    created_user_name = "created_name"
    with_mocks do
      mock identity_host, "create-user", fn message ->
        assert message["payload"]["user-name"] == user_name
        assert message["payload"]["attributes"] == attributes
        body = %{
          "user-id" => created_user_id,
          "user-name" => created_user_name}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      {:ok, %{host: identity_host, id: created_user_id}, created_user_name} =
        User.create(presentation_user, identity_host, user_name, attributes)
      query = from l in UserLink,
        where: l.presentation_user_id == ^presentation_user.id,
        where: l.user == ^%{host: identity_host, id: created_user_id}
      assert 1 == DB.Repo.aggregate(query, :count, :id)
    end
  end

  test "check_user_name_availability when the name is available" do
    user_name = "name1"
    suggestions = ["name2"]
    identity_host = "host1"
    with_mocks do
      mock identity_host, "check-user-name-availability", fn message ->
        assert message["payload"]["user-name"] == user_name
        body = %{
          "availability" => true,
          "suggestions" => suggestions}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      {:ok, true, suggestions} =
        User.check_user_name_availability(identity_host, user_name)
    end
    with_mocks do
      mock identity_host, "check-user-name-availability", fn message ->
        assert message["payload"]["user-name"] == user_name
        body = %{
          "availability" => true}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      {:ok, true, []} =
        User.check_user_name_availability(identity_host, user_name)
    end
  end

  test "check_user_name_availability when the name is not available" do
    user_name = "name1"
    suggestions = ["name2"]
    identity_host = "host1"
    with_mocks do
      mock identity_host, "check-user-name-availability", fn message ->
        assert message["payload"]["user-name"] == user_name
        body = %{
          "availability" => false,
          "suggestions" => suggestions}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      {:ok, false, suggestions} =
        User.check_user_name_availability(identity_host, user_name)
    end
    with_mocks do
      mock identity_host, "check-user-name-availability", fn message ->
        assert message["payload"]["user-name"] == user_name
        body = %{
          "availability" => false}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      {:ok, false, []} =
        User.check_user_name_availability(identity_host, user_name)
    end
  end

  test "update_user_name" do
    user = %{host: "host1", id: "id1"}
    new_user_name = "name2"
    suggestions = ["name2"]
    with_mocks do
      mock user.host, "update-user-name", fn message ->
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["user-name"] == new_user_name
        body = %{
          "user-name" => new_user_name,
          "suggestions" => suggestions}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert {:ok, new_user_name, suggestions} ==
        User.update_user_name(user, new_user_name)
    end
    with_mocks do
      mock user.host, "update-user-name", fn message ->
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["user-name"] == new_user_name
        body = %{
          "user-name" => new_user_name}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert {:ok, new_user_name, []} ==
        User.update_user_name(user, new_user_name)
    end
  end

  test "update_user_attributes" do
    user = %{host: "host1", id: "id1"}
    attributes = [
      %{"protocol" => "yayaka",
        "type" => "name",
        "value" => %{"text" => "Name 2"}}]
    with_mocks do
      mock user.host, "update-user-attributes", fn message ->
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["attributes"] == attributes
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert :ok == User.update_user_attributes(user, attributes)
    end
  end

  test "fetch" do
    user = %{host: "host1", id: "id1"}
    user_name = "name1"
    attributes = [
      %{"protocol" => "yayaka",
        "type" => "name",
        "value" => %{"text" => "Name 2"}}]
    authorized_services = [
      %{"host" => "host2",
        "service" => "presentation",
        "sender-host" => "host3"}]
    with_mocks do
      mock user.host, "fetch-user", fn message ->
        assert message["payload"]["user-id"] == user.id
        body = %{
          "user-name" => user_name,
          "attributes" => attributes,
          "authorized-services" => authorized_services}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert {:ok,
        user_name,
        attributes,
        authorized_services} == User.fetch(user)
    end
  end

  test "fetch_by_name" do
    user = %{host: "host1", id: "id1"}
    user_name = "name1"
    attributes = [
      %{"protocol" => "yayaka",
        "type" => "name",
        "value" => %{"text" => "Name 2"}}]
    authorized_services = [
      %{"host" => "host2",
        "service" => "presentation",
        "sender-host" => "host3"}]
    with_mocks do
      mock user.host, "fetch-user-by-name", fn message ->
        assert message["payload"]["user-name"] == user_name
        body = %{
          "user-id" => user.id,
          "attributes" => attributes,
          "authorized-services" => authorized_services}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert {:ok,
        user.id,
        attributes,
        authorized_services} == User.fetch_by_name(user.host, user_name)
    end
  end

  test "get_token" do
    user = %{host: "host1", id: "id1"}
    presentation_host = "host2"
    token = "token1"
    expires = DateTime.utc_now() |> DateTime.to_unix()
    with_mocks do
      mock user.host, "get-token", fn message ->
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["presentation-host"] == presentation_host
        body = %{
          "token" => token,
          "expires" => expires}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert {:ok, token, expires} == User.get_token(user, presentation_host)
    end
  end

  test "authenticate_user" do
    user = %{host: "host1", id: "id1"}
    token = "token1"
    presentation_user = %PresentationUser{
      name: "name1",
      password_hash: hashpwsalt("password1")
    } |> DB.Repo.insert!()
    with_mocks do
      mock user.host, "authenticate-user", fn message ->
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["token"] == token
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert :ok == User.authenticate_user(presentation_user, user, token)
      query = from l in UserLink,
        where: l.presentation_user_id == ^presentation_user.id,
        where: l.user == ^user
    end
  end

  test "authorize_service" do
    user = %{host: "host1", id: "id1"}
    service = %{host: "host2", service: :social_graph}
    with_mocks do
      mock user.host, "authorize-service", fn message ->
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["host"] == service.host
        assert message["payload"]["service"] == "social-graph"
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert :ok == User.authorize_service(user, service)
    end
  end

  test "revoke_service_authorization" do
    user = %{host: "host1", id: "id1"}
    service = %{host: "host2", service: :social_graph}
    with_mocks do
      mock user.host, "revoke-service-authorization", fn message ->
        assert message["payload"]["user-id"] == user.id
        assert message["payload"]["host"] == service.host
        assert message["payload"]["service"] == "social-graph"
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      assert :ok == User.revoke_service_authorization(user, service)
    end
  end
end
