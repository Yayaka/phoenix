defmodule Yayaka.MessageHandler do
  @behaviour YMP.MessageHandler
  @behaviour YMP.AnswerValidator

  @services Application.get_env(:yayaka, :message_handlers)

  @impl YMP.MessageHandler
  def handle(%{"service" => service} = message) do
    case Map.get(@services, service) do
      %{module: module} ->
        apply(module, :handle, [message])
    end
  end

  @impl YMP.AnswerValidator
  def validate_answer(%{"payload" => %{"status" => "ok"}}), do: :ok
  def validate_answer(_), do: :error

  defmodule Utils do
    def new_answer(message, body) do
      payload = %{
        "status" => "ok",
        "body" => body
      }
      YMP.Message.new_answer(message, payload)
    end

    def get_sender(message) do
      sender = message["sender"]
      %{host: sender["host"], service: sender["service"]}
    end

    def fetch_user(host, user_id, service) do
      message = YMP.Message.new(host,
                                "yayaka", "identity", "fetch-user",
                                %{"user-id" => user_id},
                                "yayaka", service)
      {:ok, answer} = YMP.MessageGateway.request(message)
      answer["payload"]["body"]
    end

    def is_authorized(user_info, service) do
      services = user_info["authorized-services"]
      Enum.any?(services, fn s ->
        s["host"] == service.host and
        s["service"] == to_string(service.service)
      end)
    end

    def get_attribute(user_info, protocol, key) do
      Enum.find(user_info["attributes"], fn attribute ->
        attribute["protocol"] == protocol and
        attribute["key"] == key
      end)
    end

    def to_datetime(inserted_at) do
      inserted_at
      |> NaiveDateTime.to_iso8601
    end
  end
end
