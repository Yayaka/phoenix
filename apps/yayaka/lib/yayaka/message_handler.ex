defmodule Yayaka.MessageHandler do
  @behaviour Amorphos.MessageHandler
  @behaviour Amorphos.AnswerValidator

  @services Application.get_env(:yayaka, :message_handlers)

  @impl Amorphos.MessageHandler
  def handle(%{"service" => service} = message) do
    case Map.get(@services, service) do
      %{module: module} ->
        apply(module, :handle, [message])
    end
  end

  @impl Amorphos.AnswerValidator
  def validate_answer(%{"payload" => %{"status" => "ok"}}), do: :ok
  def validate_answer(_), do: :error

  defmodule Utils do
    def new_answer(message, body) do
      payload = %{
        "status" => "ok",
        "body" => body
      }
      Amorphos.Message.new_answer(message, payload)
    end

    def get_sender(message) do
      sender = message["sender"]
      %{host: sender["host"], service: sender["service"]}
    end

    def to_datetime(inserted_at) do
      inserted_at
      |> NaiveDateTime.to_iso8601
    end
  end
end
