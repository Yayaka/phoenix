defmodule Web.YayakaUserControllerTest do
  use Web.ConnCase
  import YMP.TestMessageHandler, only: [with_mocks: 1, mock: 3]
  alias Yayaka.MessageHandler.Utils

  @user %{host: "host1", id: "id1"}

  defmodule Macros do
    defmacro with_error(action, do: block) do
      quote do
        with_mocks do
          mock @user.host, unquote(action), fn message ->
            payload = %{"status" => "error", "body" => %{}}
            answer = YMP.Message.new_answer(message, payload)
            YMP.MessageGateway.push(answer)
          end
          unquote(block)
        end
      end
    end
  end

  def sign_up(conn, with_yayaka_user \\ true) do
    {:ok, user} = YayakaPresentation.User.sign_up("name1", "password1")
    conn
    |> bypass_through(Web.Router, :browser)
    |> get("/")
    |> Guardian.Plug.sign_in(%{id: user.id, name: user.name})
    |> put_session(:yayaka_user, (if with_yayaka_user, do: @user, else: nil))
    |> send_resp(200, "")
    |> recycle()
  end

  def without_yayaka_user(conn) do
    conn
    |> delete_session(:yayaka_user)
  end

  test "GET /yayaka without signing in", %{conn: conn} do
    conn = conn
           |> get yayaka_user_path(conn, :index)
    response = html_response(conn, 200)
    refute response =~ "Create user"
    assert response =~ "Check user name availability"
    refute response =~ "Update user name"
    refute response =~ "Update user attributes"
    assert response =~ "Fetch user"
    refute response =~ "Get token"
    refute response =~ "Authenticate user"
    refute response =~ "Authorize service"
    refute response =~ "Revoke service authorization"
  end

  test "GET /yayaka with signing in", %{conn: conn} do
    conn = sign_up(conn, false)
           |> get yayaka_user_path(conn, :index)
    response = html_response(conn, 200)
    assert response =~ "Create user"
    assert response =~ "Check user name availability"
    refute response =~ "Update user name"
    refute response =~ "Update user attributes"
    assert response =~ "Fetch user"
    refute response =~ "Get token"
    refute response =~ "Authenticate user"
    refute response =~ "Authorize service"
    refute response =~ "Revoke service authorization"
  end

  test "GET /yayaka with signing in and a yayaka user", %{conn: conn} do
    conn = sign_up(conn)
           |> get yayaka_user_path(conn, :index)
    response = html_response(conn, 200)
    assert response =~ "Create user"
    assert response =~ "Check user name availability"
    assert response =~ "Update user name"
    assert response =~ "Update user attributes"
    assert response =~ "Fetch user"
    assert response =~ "Get token"
    assert response =~ "Authenticate user"
    assert response =~ "Authorize service"
    assert response =~ "Revoke service authorization"
  end

  # create-user

  test "POST /yayaka/create-user", %{conn: conn} do
    identity_host = "host1"
    user_name = "name1"
    attributes = [
      %{"protocol" => "yayaka",
        "type" => "name",
        "value" => %{"text" => "Name 2"}}]
    created_user_id = "id1"
    created_user_name = "name3"
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
      params = %{
        "host" => identity_host,
        "name" => user_name,
        "attributes" => Poison.encode!(attributes)
      }
      conn = sign_up(conn)
             |> post(yayaka_user_path(conn, :create_user), params: params)
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ "created"
    end
  end

  test "POST /yayaka/create-user fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "create-user" do
      params = %{
        "host" => "host1",
        "name" => "name1",
        "attributes" => Poison.encode!([])
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :create_user), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # check-user-name-availability

  test "POST /yayaka/check-user-name-availability", %{conn: conn} do
    identity_host = "host1"
    user_name = "name1"
    suggestions = ["name2", "name3"]
    with_mocks do
      mock identity_host, "check-user-name-availability", fn message ->
        assert message["payload"]["user-name"] == user_name
        body = %{
          "availability" => true,
          "suggestions" => suggestions}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => identity_host,
        "name" => user_name
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :check_user_name_availability), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ "available"
    end
  end

  test "POST /yayaka/check-user-name-availability fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "check-user-name-availability" do
      params = %{
        "host" => "host1",
        "name" => "name1",
        "attributes" => Poison.encode!([])
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :check_user_name_availability), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # update-user-name

  test "POST /yayaka/update-user-name", %{conn: conn} do
    new_user_name = "name1"
    suggestions = ["name2", "name3"]
    with_mocks do
      mock @user.host, "update-user-name", fn message ->
        assert message["payload"]["user-id"] == @user.id
        assert message["payload"]["user-name"] == new_user_name
        body = %{
          "user-name" => new_user_name,
          "suggestions" => suggestions}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => @user.host,
        "id" => @user.id,
        "name" => new_user_name
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :update_user_name), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ new_user_name
    end
  end

  test "POST /yayaka/update-user-name fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "update-user-name" do
      params = %{
        "host" => "host1",
        "name" => "name1"
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :update_user_name), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # update-user-attributes

  test "POST /yayaka/update-user-attributes", %{conn: conn} do
    attributes = [
      %{"protocol" => "yayaka",
        "type" => "name",
        "value" => %{"text" => "Name 2"}}]
    with_mocks do
      mock @user.host, "update-user-attributes", fn message ->
        assert message["payload"]["user-id"] == @user.id
        assert message["payload"]["attributes"] == attributes
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => @user.host,
        "id" => @user.id,
        "attributes" => Poison.encode!(attributes)
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :update_user_attributes), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ "updated"
    end
  end

  test "POST /yayaka/update-user-attributes fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "update-user-attributes" do
      params = %{
        "host" => @user.host,
        "id" => @user.id,
        "attributes" => Poison.encode!([])
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :update_user_attributes), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # fetch-user

  test "POST /yayaka/fetch-user", %{conn: conn} do
    user_name = "name1"
    attributes = [
      %{"protocol" => "yayaka",
        "type" => "name",
        "value" => %{"text" => "Name 2"}}]
    authorized_services = [
      %{"host" => "host1", "service" => "presentation"},
      %{"host" => "host1", "service" => "repository"}]
    with_mocks do
      mock @user.host, "fetch-user", fn message ->
        assert message["payload"]["user-id"] == @user.id
        body = %{
          "user-name" => user_name,
          "attributes" => attributes,
          "authorized-services" => authorized_services}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => @user.host,
        "id" => @user.id
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :fetch_user), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ "name1"
    end
  end

  test "POST /yayaka/fetch-user fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "fetch-user" do
      params = %{
        "host" => @user.host,
        "id" => @user.id,
        "attributes" => Poison.encode!([])
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :fetch_user), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # get-token

  test "POST /yayaka/get-token", %{conn: conn} do
    presentation_host = "host2"
    token = "token1"
    expires = DateTime.utc_now() |> DateTime.to_unix() |> Kernel.+(1000)
    with_mocks do
      mock @user.host, "get-token", fn message ->
        assert message["payload"]["user-id"] == @user.id
        assert message["payload"]["presentation-host"] == presentation_host
        body = %{
          "token" => token,
          "expires" => expires}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => presentation_host,
        "id" => @user.id
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :get_token), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ token
    end
  end

  test "POST /yayaka/get-token fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "get-token" do
      params = %{
        "host" => @user.host,
        "id" => @user.id
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :get_token), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # authenticate-user

  test "POST /yayaka/authenticate-user", %{conn: conn} do
    token = "token1"
    with_mocks do
      mock @user.host, "authenticate-user", fn message ->
        assert message["payload"]["user-id"] == @user.id
        assert message["payload"]["token"] == token
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => @user.host,
        "id" => @user.id,
        "token" => token
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :authenticate_user), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ "authenticated"
    end
  end

  test "POST /yayaka/authenticate-user fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "authenticate-user" do
      params = %{
        "host" => @user.host,
        "id" => @user.id,
        "token" => "token"
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :authenticate_user), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # authorize-service

  test "POST /yayaka/authorize-service", %{conn: conn} do
    service = %{host: "host2", service: "repository"}
    with_mocks do
      mock @user.host, "authorize-service", fn message ->
        assert message["payload"]["user-id"] == @user.id
        assert message["payload"]["host"] == service.host
        assert message["payload"]["service"] == service.service
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => service.host,
        "service" => service.service
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :authorize_service), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ "authorized"
    end
  end

  test "POST /yayaka/authorize-service fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "authorize-service" do
      params = %{
        "host" => "host1",
        "service" => "repository"
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :authorize_service), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end

  # revoke-service-authorization

  test "POST /yayaka/revoke-service-authorization", %{conn: conn} do
    service = %{host: "host2", service: "repository"}
    with_mocks do
      mock @user.host, "revoke-service-authorization", fn message ->
        assert message["payload"]["user-id"] == @user.id
        assert message["payload"]["host"] == service.host
        assert message["payload"]["service"] == service.service
        body = %{}
        answer = Utils.new_answer(message, body)
        YMP.MessageGateway.push(answer)
      end
      params = %{
        "host" => service.host,
        "service" => service.service
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :revoke_service_authorization), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :info) =~ "revoked"
    end
  end

  test "POST /yayaka/revoke-service-authorization fails", %{conn: conn} do
    import __MODULE__.Macros
    with_error "revoke-service-authorization" do
      params = %{
        "host" => "host2",
        "service" => "repository"
      }
      conn = sign_up(conn)
             |> post yayaka_user_path(conn, :revoke_service_authorization), params: params
      assert redirected_to(conn) == yayaka_user_path(conn, :index)
      assert get_flash(conn, :error) =~ "error"
    end
  end
end
