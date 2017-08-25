defmodule Web.YayakaUserController do
  use Web, :controller
  alias YayakaPresentation.User

  plug Guardian.Plug.EnsureAuthenticated, %{handler: __MODULE__} when action in [
    :create_user, :update_user_name, :update_user_attributes,
    :get_token, :authenticate_user, :authorize_service,
    :revoke_service_authorization]

  def unauthenticated(conn, _params) do
    conn
    |> put_status(401)
    |> put_flash(:error, "Authentication required")
    |> redirect(to: "/")
  end

  defp ok(conn, message) do
    conn
    |> put_flash(:info, message)
    |> redirect(to: yayaka_user_path(conn, :index))
  end

  defp error(conn, message \\ "error") do
    conn
    |> put_flash(:error, message)
    |> redirect(to: yayaka_user_path(conn, :index))
  end

  def index(conn, _params) do
    presentation_user = get_user(conn)
    user = get_yayaka_user(conn)
    actions = case {presentation_user, user} do
      {nil, _} ->
        [:check_user_name_availability, :fetch_user, :fetch_user_by_name]
      {_, nil} ->
        [:create_user, :check_user_name_availability, :fetch_user, :fetch_user_by_name]
      _ ->
        [:create_user, :check_user_name_availability,
         :update_user_name, :update_user_attributes,
         :fetch_user, :fetch_user_by_name,
         :get_token, :authenticate_user,
         :authorize_service, :revoke_service_authorization]
    end
    render conn, "index.html", actions: actions
  end

  def create_user(conn, %{"params" => params}) do
    presentation_user = get_user(conn)
    %{"host" => identity_host,
      "name" => user_name,
      "attributes" => attributes} = params
    attributes = Poison.decode!(attributes)
    case User.create(presentation_user, identity_host, user_name, attributes) do
      {:ok, user, name} ->
        ok(conn, """
        user is created.
        id: #{user.id}
        name: #{name}
        """)
      _ ->
        error(conn)
    end
  end

  def check_user_name_availability(conn, %{"params" => params}) do
    %{"host" => identity_host,
      "name" => user_name} = params
    case User.check_user_name_availability(identity_host, user_name) do
      {:ok, true, suggestions} ->
        ok(conn, """
        #{user_name}@#{identity_host} is available.
        """)
      {:ok, false, suggestions} ->
        ok(conn, """
        #{user_name}@#{identity_host} is NOT available.
        """)
      _ ->
        error(conn)
    end
  end

  def update_user_name(conn, %{"params" => params}) do
    user = get_yayaka_user!(conn)
    %{"name" => new_user_name} = params
    case User.update_user_name(user, new_user_name) do
      {:ok, name, suggestions} ->
        ok(conn, """
        user name is updated.
        name: #{name}
        suggestions: #{inspect suggestions}
        """)
      _ ->
        error(conn)
    end
  end

  def update_user_attributes(conn, %{"params" => params}) do
    user = get_yayaka_user!(conn)
    %{"attributes" => attributes} = params
    attributes = Poison.decode!(attributes)
    case User.update_user_attributes(user, attributes) do
      :ok ->
        ok(conn, """
        user attributes is updated.
        """)
      _ ->
        error(conn)
    end
  end

  def fetch_user(conn, %{"params" => params}) do
    %{"host" => identity_host,
      "id" => user_id} = params
    user = %{host: identity_host, id: user_id}
    case User.fetch(user) do
      {:ok, user_name, attributes, authorize_services} ->
        ok(conn, """
        user is fetched.
        host: #{identity_host}
        id: #{user_id}
        name: #{user_name}
        attributes: #{inspect attributes}
        authorize_service: #{inspect authorize_services}
        """)
      _ ->
        error(conn)
    end
  end

  def fetch_user_by_name(conn, %{"params" => params}) do
    %{"host" => identity_host,
      "name" => name} = params
    case User.fetch_by_name(identity_host, name) do
      {:ok, user_id, attributes, authorize_services} ->
        ok(conn, """
        user is fetched.
        host: #{identity_host}
        id: #{user_id}
        name: #{name}
        attributes: #{inspect attributes}
        authorize_service: #{inspect authorize_services}
        """)
      _ ->
        error(conn)
    end
  end

  def get_token(conn, %{"params" => params}) do
    user = get_yayaka_user!(conn)
    %{"host" => presentation_host} = params
    case User.get_token(user, presentation_host) do
      {:ok, token, expires} ->
        ok(conn, """
        here is token.
        host: #{presentation_host}
        token: #{token}
        expires: #{expires}
        """)
      _ ->
        error(conn)
    end
  end

  def authenticate_user(conn, %{"params" => params}) do
    presentation_user = get_user(conn)
    %{"host" => identity_host,
      "id" => user_id,
      "token" => token} = params
    user = %{host: identity_host, id: user_id}
    case User.authenticate_user(presentation_user, user, token) do
      :ok ->
        ok(conn, """
        user is authenticated.
        """)
      _ ->
        error(conn)
    end
  end

  def authorize_service(conn, %{"params" => params}) do
    user = get_yayaka_user!(conn)
    %{"host" => host,
      "service" => service} = params
    service = %{host: host, service: service}
    case User.authorize_service(user, service) do
      :ok ->
        ok(conn, """
        service is authorized.
        """)
      _ ->
        error(conn)
    end
  end

  def revoke_service_authorization(conn, %{"params" => params}) do
    user = get_yayaka_user!(conn)
    %{"host" => host,
      "service" => service} = params
    service = %{host: host, service: service}
    case User.revoke_service_authorization(user, service) do
      :ok ->
        ok(conn, """
        service authorization is revoked.
        """)
      _ ->
        error(conn)
    end
  end
end
