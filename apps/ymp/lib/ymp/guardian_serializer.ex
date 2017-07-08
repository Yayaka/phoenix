defmodule YMP.GuardianSerializer do
  @behaviour Guardian.Serializer

  def for_token(map) when is_map(map) do
    {:ok, "map:#{Poison.encode!(map)}"}
  end
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("map:" <> map) do
    case Poison.decode(map) do
      {:ok, map} -> {:ok, map}
      _ -> {:error, "Invalid JSON"}
    end
  end
  def from_token(_), do: {:error, "Unknown resource type"}
end
