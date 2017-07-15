defmodule Yayaka.MessageHandler do
  @behaviour YMP.MessageHandler

  @services Application.get_env(:yayaka, :services)

  def handle(%{"service" => service} = message) do
    case Map.get(@services, [service]) do
      %{module: module} ->
        apply(module, :handle, [message])
    end
  end
end
