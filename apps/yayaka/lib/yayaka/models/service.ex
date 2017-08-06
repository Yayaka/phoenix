defmodule Yayaka.Service do
  @behaviour Ecto.Type

  @services_atom [:identity, :repository, :social_graph, :presentation, :notification]
  @services_string Enum.map(@services_atom, fn atom ->
    to_string(atom)
    |> String.replace("_", "-")
  end)
  @atom_string_map Enum.zip(@services_atom, @services_string) |> Enum.into(%{})
  @string_atom_map Enum.zip(@services_string, @services_atom) |> Enum.into(%{})

  def validate_service(changeset, field, service) do
    Ecto.Changeset.validate_change(changeset, field, fn ^field, map ->
      case map do
        %{service: ^service} -> [] # No errors
        _ -> [{field, "must be #{service}"}]
      end
    end)
  end

  # Callbacks
  def type, do: :string

  def cast(%{host: host, service: service}), do: do_cast(host, service)
  def cast(%{"host" => host, "service" => service}), do: do_cast(host, service)
  def cast(_), do: :error

  def do_cast(host, service) when service in @services_atom do
    case Ecto.Type.cast(:string, host) do
      {:ok, host} -> {:ok, %{host: host, service: service}}
      _ -> :error
    end
  end
  def do_cast(host, service)  when service in @services_string do
    case Ecto.Type.cast(:string, host) do
      {:ok, host} ->
        index = Enum.find_index(@services_string, fn string -> string == service end)
        service = Enum.at(@services_atom, index)
        {:ok, %{host: host, service: service}}
      _ -> :error
    end
  end

  # delimiter is ":"
  def load(string) do
    [service, host] = String.split(string, ":", parts: 2)
    {:ok, %{host: host, service: service}}
  end

  def dump(%{host: host, service: service}) do
    service = @atom_string_map[service]
    {:ok, "#{service}:#{host}"}
  end
end
