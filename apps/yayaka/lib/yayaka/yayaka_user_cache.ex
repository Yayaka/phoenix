defmodule Yayaka.YayakaUserCache do
  alias Yayaka.YayakaUser

  @spec get_or_fetch(map) :: {:ok, %YayakaUser{}} | :error
  def get_or_fetch(user) do
    case Cachex.get(:yayaka_user, user) do
      {:ok, cache} -> {:ok, cache}
      {:missing, _} ->
        payload = %{"user-id" => user.id}
        message = YMP.Message.new(user.host,
                                  "yayaka", "identity", "fetch-user",
                                  payload, "yayaka", "presentation")
        case YMP.MessageGateway.request(message) do
          {:ok, answer} ->
            %{"user-name" => user_name,
              "attributes" => attributes,
              "authorized-services" => authorized_services} = answer["payload"]["body"]
            yayaka_user = %YayakaUser{
              host: user.host,
              id: user.id,
              name: user_name,
              attributes: attributes,
              authorized_services: authorized_services}
            Cachex.set(:yayaka_user, user, yayaka_user)
            Cachex.set(:yayaka_user_name, %{host: user.host, name: yayaka_user.name}, user.id)
            {:ok, yayaka_user}
          _ ->
            :error
        end
    end
  end

  @spec get_or_fetch_by_name(String.t, String.t) :: {:ok, %YayakaUser{}} | :error
  def get_or_fetch_by_name(host, name) do
    key = %{host: host, name: name}
    case Cachex.get(:yayaka_user_name, key) do
      {:ok, id} ->
        case Cachex.get(:yayaka_user, %{host: host, id: id}) do
          {:ok, cache} ->
            if cache.name == name do
              {:ok, cache}
            else
              Cachex.del(:yayaka_user_name, key)
              :error
            end
          {:missing, _} ->
            case fetch_by_name(host, name) do
              {:ok, yayaka_user} ->
                Cachex.set(:yayaka_user, %{host: host, id: yayaka_user.id}, yayaka_user)
                Cachex.set(:yayaka_user_name, %{host: host, name: name}, yayaka_user.id)
                {:ok, yayaka_user}
              :error -> :error
            end
        end
      {:missing, _} ->
        case fetch_by_name(host, name) do
          {:ok, yayaka_user} ->
            Cachex.set(:yayaka_user, %{host: host, id: yayaka_user.id}, yayaka_user)
            Cachex.set(:yayaka_user_name, %{host: host, name: name}, yayaka_user.id)
            {:ok, yayaka_user}
          :error -> :error
        end
    end
  end

  defp fetch_by_name(host, name) do
    payload = %{"user-name" => name}
    message = YMP.Message.new(host,
                              "yayaka", "identity", "fetch-user-by-name",
                              payload, "yayaka", "presentation")
    case YMP.MessageGateway.request(message) do
      {:ok, answer} ->
        %{"user-id" => user_id,
          "attributes" => attributes,
          "authorized-services" => authorized_services} = answer["payload"]["body"]
        yayaka_user = %YayakaUser{
          host: host,
          id: user_id,
          name: name,
          attributes: attributes,
          authorized_services: authorized_services}
        {:ok, yayaka_user}
      _ ->
        :error
    end
  end
end
