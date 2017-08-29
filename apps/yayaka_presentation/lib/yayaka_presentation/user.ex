defmodule YayakaPresentation.User do
  alias YayakaPresentation.User
  alias YayakaPresentation.PresentationUser
  alias YayakaPresentation.UserLink
  alias Yayaka.YayakaUserCache
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
  @typep link_id :: integer
  @typep user_link :: %UserLink{}

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

  @spec get_user_links(presentation_user) :: [user_link]
  def get_user_links(presentation_user) do
    query = from l in UserLink,
      where: l.presentation_user_id == ^presentation_user.id
    DB.Repo.all(query)
  end

  @spec linked?(presentation_user, user) :: boolean
  def linked?(presentation_user, user) do
    query = from l in UserLink,
      where: l.presentation_user_id == ^presentation_user.id,
      where: l.user == ^user
    1 == DB.Repo.aggregate(query, :count, :id)
  end

  @spec create(presentation_user, host, name, attributes) :: {:ok, user, name} | :error
  def create(presentation_user, identity_host, name, attributes) do
    payload = %{
      "user-name" => name,
      "attributes" => attributes}
    message = Amorphos.Message.new(identity_host,
                              "yayaka", "identity", "create-user",
                              payload, "yayaka", "presentation")
    with {:ok, answer} <- Amorphos.MessageGateway.request(message),
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
    message = Amorphos.Message.new(identity_host,
                              "yayaka", "identity", "check-user-name-availability",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"availability" => availability} = answer["payload"]["body"]
        suggestions = Map.get(answer["payload"]["body"], "suggestions", [])
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
    message = Amorphos.Message.new(user.host,
                              "yayaka", "identity", "update-user-name",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"user-name" => user_name} = answer["payload"]["body"]
        suggestions = Map.get(answer["payload"]["body"], "suggestions", [])
        YayakaUserCache.delete(user)
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
    message = Amorphos.Message.new(user.host,
                              "yayaka", "identity", "update-user-attributes",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        YayakaUserCache.delete(user)
        :ok
      _ ->
        :error
    end
  end

  @spec fetch(user) :: {:ok, name, attributes, [Yayaka.Service.t]} | :error
  def fetch(user) do
    payload = %{
      "user-id" => user.id}
    message = Amorphos.Message.new(user.host,
                              "yayaka", "identity", "fetch-user",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"user-name" => user_name,
          "attributes" => attributes,
          "authorized-services" => authorized_services} = answer["payload"]["body"]
        {:ok, user_name, attributes, authorized_services}
      _ ->
        :error
    end
  end

  @spec fetch_by_name(host, user) :: {:ok, user_id, attributes, [Yayaka.Service.t]} | :error
  def fetch_by_name(identity_host, name) do
    payload = %{
      "user-name" => name}
    message = Amorphos.Message.new(identity_host,
                              "yayaka", "identity", "fetch-user-by-name",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"user-id" => user_id,
          "attributes" => attributes,
          "authorized-services" => authorized_services} = answer["payload"]["body"]
        {:ok, user_id, attributes, authorized_services}
      _ ->
        :error
    end
  end

  @spec get_token(user, host) :: {:ok, token, expires} | :error
  def get_token(user, presentation_host) do
    payload = %{
      "user-id" => user.id,
      "presentation-host" => presentation_host}
    message = Amorphos.Message.new(user.host,
                              "yayaka", "identity", "get-token",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
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
    message = Amorphos.Message.new(user.host,
                              "yayaka", "identity", "authenticate-user",
                              payload, "yayaka", "presentation")
    with {:ok, _answer} <- Amorphos.MessageGateway.request(message),
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
    message = Amorphos.Message.new(user.host,
                              "yayaka", "identity", "authorize-service",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, _answer} ->
        YayakaUserCache.delete(user)
        :ok
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
    message = Amorphos.Message.new(user.host,
                              "yayaka", "identity", "revoke-service-authorization",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, _answer} ->
        YayakaUserCache.delete(user)
        :ok
      _ -> :error
    end
  end

  @spec fetch_relations(host, user) :: {:ok, [{host, user}], [{host, user}]} | :error
  def fetch_relations(host, user) do
    payload = %{
      "identity-host" => user.host,
      "user-id" => user.id}
    message = Amorphos.Message.new(host,
                              "yayaka", "social-graph", "fetch-user-relations",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"subscriptions" => subscriptions,
          "subscribers" => subscribers} = answer["payload"]["body"]
        subscriptions = map_relations(subscriptions)
        subscribers = map_relations(subscribers)
        {:ok, subscriptions, subscribers}
      _ -> :error
    end
  end

  defp map_relations(relations) do
    Enum.map(relations, fn relation ->
      %{"identity-host" => identity_host,
        "user-id" => user_id,
        "social-graph-host" => social_graph_host} = relation
      {%{host: identity_host, id: user_id}, social_graph_host}
    end)
  end

  @spec subscribe(host, user, host, user) :: :ok | :error
  def subscribe(host, user, target_host, target_user) do
    payload = %{
      "subscriber-identity-host" => user.host,
      "subscriber-user-id" => user.id,
      "publisher-identity-host" => target_user.host,
      "publisher-user-id" => target_user.id,
      "publisher-social-graph-host" => target_host}
    message = Amorphos.Message.new(host,
                              "yayaka", "social-graph", "subscribe",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, _answer} -> :ok
      _ -> :error
    end
  end

  @spec unsubscribe(host, user, host, user) :: :ok | :error
  def unsubscribe(host, user, target_host, target_user) do
    payload = %{
      "subscriber-identity-host" => user.host,
      "subscriber-user-id" => user.id,
      "publisher-identity-host" => target_user.host,
      "publisher-user-id" => target_user.id,
      "publisher-social-graph-host" => target_host}
    message = Amorphos.Message.new(host,
                              "yayaka", "social-graph", "unsubscribe",
                              payload, "yayaka", "presentation")
    case Amorphos.MessageGateway.request(message) do
      {:ok, _answer} -> :ok
      _ -> :error
    end
  end
end
