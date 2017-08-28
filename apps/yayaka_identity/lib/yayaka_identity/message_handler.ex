defmodule YayakaIdentity.MessageHandler do
  @behaviour Amorphos.MessageHandler

  alias YayakaIdentity.IdentityUser
  alias YayakaIdentity.UserAttribute
  alias YayakaIdentity.AuthorizedService
  alias Yayaka.MessageHandler.Utils
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  defp is_authorized(service, user_id) do
    import Ecto.Query
    query = from a in AuthorizedService,
    where: a.identity_user_id == ^user_id,
    where: a.service == ^service
    1 == DB.Repo.aggregate(query, :count, :id)
  end

  def handle(%{"action" => "create-user"} = message) do
    %{"user-name" => user_name,
      "attributes" => attributes} = message["payload"]
    sender = Utils.get_sender(message)
    attributes = Enum.map(attributes, fn attribute ->
      Map.put(attribute, "sender", sender)
    end)
    params = %{
      id: UUID.uuid4(),
      name: user_name,
      user_attributes: attributes,
      sender: sender
    }
    changeset = IdentityUser.changeset(%IdentityUser{}, params)
    query = from u in IdentityUser, where: u.name == ^user_name
    changeset = if DB.Repo.aggregate(query, :count, :id) != 0 do
      force_change(changeset, :name, UUID.uuid4())
    else
      changeset
    end
    identity_user = DB.Repo.insert!(changeset)
    params = %{
      identity_user_id: identity_user.id,
      service: sender,
      sender: sender}
    changeset = AuthorizedService.changeset(%AuthorizedService{}, params)
    DB.Repo.insert!(changeset)
    body = %{
      "user-id" => identity_user.id,
      "user-name" => identity_user.name
    }
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "check-user-name-availability"} = message) do
    %{"user-name" => user_name} = message["payload"]
    query = from u in IdentityUser, where: u.name == ^user_name
    availability = DB.Repo.aggregate(query, :count, :id) == 0
    body = %{
      "availability" => availability
    }
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "update-user-name"} = message) do
    %{"user-id" => user_id,
      "user-name" => user_name} = message["payload"]
    sender = Utils.get_sender(message)
    true = is_authorized(sender, user_id)
    query = from u in IdentityUser, where: u.name == ^user_name
    availability = DB.Repo.aggregate(query, :count, :id) == 0
    user = DB.Repo.get(IdentityUser, user_id)
    user = if availability do
      user
      |> Ecto.Changeset.change(name: user_name)
      |> DB.Repo.update!()
    else
      user
    end
    body = %{
      "user-name" => user.name
    }
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "update-user-attributes"} = message) do
    %{"user-id" => user_id,
      "attributes" => attributes} = message["payload"]
    sender = Utils.get_sender(message)
    true = is_authorized(sender, user_id)
    query = IdentityUser
            |> where([i], i.id == ^user_id)
            |> preload([:user_attributes])
    user = DB.Repo.one!(query)
    multi = Ecto.Multi.new
    multi = Enum.reduce(attributes, multi, fn attribute, multi ->
      attribute = Map.put(attribute, "sender", sender)
      attribute = Map.put(attribute, "identity_user_id", user_id)
      %{"protocol" => protocol,
        "key" => key,
        "value" => value} = attribute
      name = "#{protocol}:#{key}"
      found = Enum.find(user.user_attributes, fn struct ->
        match?(%UserAttribute{protocol: ^protocol, key: ^key}, struct)
      end)
      case {found, value} do
        {%UserAttribute{}, nil} ->
          Ecto.Multi.delete(multi, name, found)
        {%UserAttribute{id: id}, _} ->
          attribute = Map.put(attribute, "id", id)
          changeset = UserAttribute.changeset(found, attribute)
          Ecto.Multi.update(multi, name, changeset)
        {nil, value} when not is_nil(value) ->
          changeset = UserAttribute.changeset(%UserAttribute{}, attribute)
          Ecto.Multi.insert(multi, name, changeset)
        _ ->
          multi
      end
    end)
    {:ok, _result} = DB.Repo.transaction(multi)
    answer = Utils.new_answer(message, %{})
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "fetch-user"} = message) do
    %{"user-id" => user_id} = message["payload"]
    query = IdentityUser
            |> where([i], i.id == ^user_id)
            |> preload([:user_attributes, :authorized_services])
    user = DB.Repo.one!(query)
    attributes = Enum.map(user.user_attributes, fn attribute ->
      %UserAttribute{
        protocol: protocol, key: key, value: value, sender: sender} = attribute
      %{"protocol" => protocol,
        "key" => key,
        "value" => value,
        "sender-host" => sender.host}
    end)
    authorized_services = Enum.map(user.authorized_services, fn service ->
      %AuthorizedService{service: service, sender: sender} = service
      %{"host" => service.host,
        "service" => to_string(service.service),
        "sender-host" => sender.host}
    end)
    body = %{
      "user-name" => user.name,
      "attributes" => attributes,
      "authorized-services" => authorized_services}
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "fetch-user-by-name"} = message) do
    %{"user-name" => user_name} = message["payload"]
    query = IdentityUser
            |> where([i], i.name == ^user_name)
            |> preload([:user_attributes, :authorized_services])
    user = DB.Repo.one!(query)
    attributes = Enum.map(user.user_attributes, fn attribute ->
      %UserAttribute{
        protocol: protocol, key: key, value: value, sender: sender} = attribute
      %{"protocol" => protocol,
        "key" => key,
        "value" => value,
        "sender-host" => sender.host}
    end)
    authorized_services = Enum.map(user.authorized_services, fn service ->
      %AuthorizedService{service: service, sender: sender} = service
      %{"host" => service.host,
        "service" => to_string(service.service),
        "sender-host" => sender.host}
    end)
    body = %{
      "user-id" => user.id,
      "attributes" => attributes,
      "authorized-services" => authorized_services}
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "get-token"} = message) do
    %{"user-id" => user_id,
      "presentation-host" => host} = message["payload"]
    sender = Utils.get_sender(message)
    true = is_authorized(sender, user_id)
    resource = %{host: host}
    {:ok, token, claims} = Guardian.encode_and_sign(resource)
    expires = Map.get(claims, "exp")
    body = %{
      "token" => token,
      "expires" => expires
    }
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "authenticate-user"} = message) do
    %{"user-id" => user_id,
      "token" => token} = message["payload"]
    sender = Utils.get_sender(message)
    sender_host = sender.host
    {:ok, claims} = Guardian.decode_and_verify(token)
    {:ok, %{"host" => ^sender_host}} = Guardian.serializer.from_token(claims["sub"])
    if not is_authorized(sender, user_id) do
      params = %{identity_user_id: user_id,
        service: sender,
        sender: sender}
      changeset = AuthorizedService.changeset(%AuthorizedService{}, params)
      authorized_service = DB.Repo.insert!(changeset)
    end
    answer = Utils.new_answer(message, %{})
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "authorize-service"} = message) do
    %{"user-id" => user_id,
      "host" => host,
      "service" => service} = message["payload"]
    sender = Utils.get_sender(message)
    service = %{host: host, service: service}
    true = is_authorized(sender, user_id)
    if not is_authorized(service, user_id) do
      params = %{identity_user_id: user_id,
        service: service,
        sender: sender}
      changeset = AuthorizedService.changeset(%AuthorizedService{}, params)
      authorized_service = DB.Repo.insert!(changeset)
    end
    answer = Utils.new_answer(message, %{})
    Amorphos.MessageGateway.push(answer)
  end

  def handle(%{"action" => "revoke-service-authorization"} = message) do
    %{"user-id" => user_id,
      "host" => host,
      "service" => service} = message["payload"]
    sender = Utils.get_sender(message)
    service = %{host: host, service: service}
    true = is_authorized(sender, user_id)
    query = from a in AuthorizedService,
      where: a.identity_user_id == ^user_id,
      where: a.service == ^service
    DB.Repo.delete_all(query)
    answer = Utils.new_answer(message, %{})
    Amorphos.MessageGateway.push(answer)
  end
end
