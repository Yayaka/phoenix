defmodule YayakaPresentation.MessageHandler do
  @behaviour Amorphos.MessageHandler

  alias YayakaPresentation.TimelineSubscriptionRegistry
  alias Yayaka.MessageHandler.Utils

  def handle(%{"action" => "push-event"} = message) do
    %{"subscription-id" => subscription_id} = message["payload"]
    event = Map.take(message["payload"], [
                       "repository-host",
                       "event-id",
                       "identity-host",
                       "user-id",
                       "protocol",
                       "type",
                       "body",
                       "sender-host",
                       "created-at"])
    TimelineSubscriptionRegistry.push_event(subscription_id, event)
    body = %{}
    answer = Utils.new_answer(message, body)
    Amorphos.MessageGateway.push(answer)
  end
end
