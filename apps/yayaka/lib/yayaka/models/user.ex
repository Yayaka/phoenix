defmodule Yayaka.User do
  @behaviour Ecto.Type

  # Callbacks
  def type, do: :string

  def cast(%{host: host, id: id}) do
    {:ok, %{host: host, id: id}}
  end
  def cast(%{"host" => host, "id" => id}) do
    {:ok, %{host: host, id: id}}
  end
  def cast(_), do: :error

  def load(user) do
    [host, id] = Poison.decode!(user)
    {:ok, %{host: host, id: id}}
  end

  def dump(%{host: host, id: id}) do
    {:ok, Poison.encode!([host, id])}
  end
end
