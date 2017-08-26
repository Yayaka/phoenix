defmodule Yayaka.YayakaUser do
  defstruct [:host, :id, :name, :attributes, :authorized_services]

  def authorizes?(yayaka_user, service) do
    {:ok, service} = Yayaka.Service.cast(service)
    services = yayaka_user.authorized_services
    Enum.any?(services, fn s ->
      s["host"] == service.host and s["service"] == service.service
    end)
  end

  def get_attribute(yayaka_user, protocol, key) do
    Enum.find(yayaka_user.attributes, fn attribute ->
      attribute["protocol"] == protocol and attribute["key"] == key
    end)
  end
end
