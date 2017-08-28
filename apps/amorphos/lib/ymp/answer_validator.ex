defmodule Amorphos.AnswerValidator do
  @doc """
  Validates a message.
  """
  @callback validate_answer(message :: map) :: :ok | :error
end
