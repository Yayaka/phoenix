defmodule YayakaPresentation.User do
  alias Yayaka.MessageHandler.Utils
  alias YayakaPresentation.User
  alias YayakaPresentation.PresentationUser
  alias YayakaPresentation.UserLink
  import Comeonin.Bcrypt, only: [hashpwsalt: 1, checkpw: 2, dummy_checkpw: 0]
  import Ecto.Query

  @typep host :: String.t
  @typep name :: String.t
  @typep password :: String.t
  @typep user_id :: String.t
  @typep presentation_user :: %PresentationUser{}
  @typep user :: %{host: host, id: user_id}
  @typep attribute :: map
  @typep attributes :: [attribute]
  @typep token :: String.t
  @typep expires :: integer

  defp insert_user_link(presentation_user, user) do
    params = %{
      presentation_user_id: presentation_user.id,
      user: user}
    changeset = UserLink.changeset(%UserLink{}, params)
    DB.Repo.insert(changeset)
  end

  @spec sign_up(name, password) :: {:ok, presentation_user} | :error
  def sign_up(name, password) do
    query = from p in PresentationUser,
      where: p.name == ^name
    if DB.Repo.aggregate(query, :count, :id) == 0 do
      params = %{
        name: name,
        password_hash: hashpwsalt(password)}
      changeset = PresentationUser.changeset(%PresentationUser{}, params)
      case DB.Repo.insert(changeset) do
        {:ok, presentation_user} -> {:ok, presentation_user}
        _ -> :error
      end
    else
      :error
    end
  end

  @spec sign_in(name, password) :: {:ok, presentation_user} | :error
  def sign_in(name, password) do
    query = from p in PresentationUser,
      where: p.name == ^name
    case DB.Repo.one(query) do
      presentation_user when not is_nil(presentation_user) ->
        if checkpw(password, presentation_user.password_hash) do
          {:ok, presentation_user}
        else
          :error
        end
      _ ->
        dummy_checkpw()
        :error
    end
  end

  @spec create(presentation_user, host, name, attributes) :: {:ok, user, name} | :error
  def create(presentation_user, identity_host, name, attributes) do
    payload = %{
      "user-name" => name,
      "attributes" => attributes}
    create_user = YMP.Message.new(identity_host,
                                  "yayaka", "identity", "create-user",
                                  payload, "yayaka", "presentation")
    with {:ok, answer} <- YMP.MessageGateway.request(create_user),
         %{"user-id" => user_id,
           "user-name" => user_name} <- answer["payload"]["body"],
         user <- %{host: identity_host, id: user_id},
         {:ok, _link} <- insert_user_link(presentation_user, user) do
      {:ok, user, user_name}
    else
      _ -> :error
    end
  end

  @spec check_user_name_availability(host, name) :: {:ok, boolean, [name]} | :error
  def check_user_name_availability(identity_host, name) do
    payload = %{
      "user-name" => name}
    message = YMP.Message.new(identity_host,
                            "yayaka", "identity", "check-user-name-availability",
                            payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"availability" => availability,
          "suggestions" => suggestions} = answer["payload"]["body"]
        {:ok, availability, suggestions}
      _ ->
        :error
    end
  end

  @spec update_user_name(user, name) :: {:ok, name, [name]} | :error
  def update_user_name(user, new_name) do
    payload = %{
      "user-id" => user.id,
      "user-name" => new_name}
    message = YMP.Message.new(user.host,
                            "yayaka", "identity", "update-user-name",
                            payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"user-name" => user_name,
          "suggestions" => suggestions} = answer["payload"]["body"]
        {:ok, user_name, suggestions}
      _ ->
        :error
    end
  end

  @spec update_user_attributes(user, attributes) :: :ok | :error
  def update_user_attributes(user, attributes) do
    payload = %{
      "user-id" => user.id,
      "attributes" => attributes}
    message = YMP.Message.new(user.host,
                            "yayaka", "identity", "update-user-attributes",
                            payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(message) do
      {:ok, answer} ->
        :ok
      _ ->
        :error
    end
  end

  @spec fetch(user) :: {:ok, name, attributes, [Yayaka.Service.t]} | :error
  def fetch(user) do
    payload = %{
      "user-id" => user.id}
    check = YMP.Message.new(user.host,
                            "yayaka", "identity", "fetch-user",
                            payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(check) do
      {:ok, answer} ->
        %{"user-name" => user_name,
          "attributes" => attributes,
          "authorized-services" => authorized_services} = answer["payload"]["body"]
        {:ok, user_name, attributes, authorized_services}
      _ ->
        :error
    end
  end

  @spec get_token(user, host) :: {:ok, token, expires} | :error
  def get_token(user, presentation_host) do
    payload = %{
      "user-id" => user.id,
      "presentation-host" => presentation_host}
    check = YMP.Message.new(user.host,
                            "yayaka", "identity", "get-token",
                            payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(check) do
      {:ok, answer} ->
        %{"token" => token,
          "expires" => expires} = answer["payload"]["body"]
        {:ok, token, expires}
      _ ->
        :error
    end
  end

  @spec authenticate_user(presentation_user, user, token) :: :ok | :error
  def authenticate_user(presentation_user, user, token) do
    payload = %{
      "user-id" => user.id,
      "token" => token}
    check = YMP.Message.new(user.host,
                            "yayaka", "identity", "authenticate-user",
                            payload, "yayaka", "presentation")
    with {:ok, _answer} <- YMP.MessageGateway.request(check),
         {:ok, _link} <- insert_user_link(presentation_user, user) do
      :ok
    else
      _ -> :error
    end
  end

  @spec authorize_service(user, Yayaka.Service.t) :: :ok | :error
  def authorize_service(user, service) do
    {:ok, service} = Yayaka.Service.cast(service)
    payload = %{
      "user-id" => user.id,
      "host" => service.host,
      "service" => service.service}
    check = YMP.Message.new(user.host,
                            "yayaka", "identity", "authorize-service",
                            payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(check) do
      {:ok, _answer} -> :ok
      _ -> :error
    end
  end

  @spec revoke_service_authorization(user, Yayaka.Service.t) :: :ok | :error
  def revoke_service_authorization(user, service) do
    {:ok, service} = Yayaka.Service.cast(service)
    payload = %{
      "user-id" => user.id,
      "host" => service.host,
      "service" => service.service}
    check = YMP.Message.new(user.host,
                            "yayaka", "identity", "revoke-service-authorization",
                            payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(check) do
      {:ok, _answer} -> :ok
      _ -> :error
    end
  end
end
