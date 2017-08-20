defmodule Yayaka.Service do
  @behaviour Ecto.Type

  @type t :: %{host: string, service: atom | String.t}

  @services_atom [:identity, :repository, :social_graph,
                  :presentation, :notification]
  @services_string ["identity", "repository", "social-graph",
                    "presentation", "notification"]
  @atom_string_map Enum.zip(@services_atom, @services_string) |> Enum.into(%{})
  @string_atom_map Enum.zip(@services_string, @services_atom) |> Enum.into(%{})

  def validate_service(changeset, field, service) when service in @services_atom do
    index = Enum.find_index(@services_atom, fn string -> string == service end)
    service = Enum.at(@services_string, index)
    validate_service(changeset, field, service)
  end
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

  def do_cast(host, service) when service in @services_string do
    case Ecto.Type.cast(:string, host) do
      {:ok, host} -> {:ok, %{host: host, service: service}}
      _ -> :error
    end
  end
  def do_cast(host, service)  when service in @services_atom do
    case Ecto.Type.cast(:string, host) do
      {:ok, host} ->
        index = Enum.find_index(@services_atom, fn string -> string == service end)
        service = Enum.at(@services_string, index)
        {:ok, %{host: host, service: service}}
      _ -> :error
    end
  end

  # delimiter is ":"
  def load(string) do
    [service, host] = String.split(string, ":", parts: 2)
    {:ok, %{host: host, service: service}}
  end

  def dump(service) do
    {:ok, %{host: host, service: service}} = cast(service)
    {:ok, "#{service}:#{host}"}
  end
end
