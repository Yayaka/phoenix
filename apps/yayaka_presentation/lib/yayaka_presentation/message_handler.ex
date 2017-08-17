defmodule YayakaPresentation.MessageHandler do
  @behaviour YMP.MessageHandler

  def handle(%{"action" => "push-event"}) do
  end

  def handle(%{"action" => "push-notification"}) do
  end
end
