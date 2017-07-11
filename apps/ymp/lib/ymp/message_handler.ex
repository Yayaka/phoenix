defmodule YMP.MessageHandler do
  @doc """
  Handles a message.
  """
  @callback handle(message :: map) :: :ok | :error
end
