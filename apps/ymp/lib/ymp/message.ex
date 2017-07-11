defmodule YMP.Message do
  def new(host, protocol, service, action, payload, sender_protocol, sender_service) do
    %{"sender" => %{
      "host" => YMP.get_host(),
      "protocol" => sender_protocol,
      "service" => sender_service},
    "id" => UUID.uuid4(),
    "host" => host,
    "protocol" => protocol,
    "service" => service,
    "action" => action,
    "payload" => payload}
  end

  def new_answer(message, payload) do
    %{"sender" => %{
      "host" => YMP.get_host(),
      "protocol" => message["protocol"],
      "service" => message["service"]},
    "id" => UUID.uuid4(),
    "reply-to" => message["id"],
    "host" => message["sender"]["host"],
    "protocol" => message["sender"]["protocol"],
    "service" => message["sender"]["service"],
    "action" => message["action"],
    "payload" => payload}
  end
end
