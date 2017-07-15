defmodule Yayaka.Service do
  @behaviour Ecto.Type

  @services_atom Application.get_env(:yayaka, :services)
  @services_string Enum.map(@services_atom, &to_string/1)

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
      {:ok, host} -> {:ok, %{host: host, service: String.to_atom(service)}}
      _ -> :error
    end
  end

  # delimiter is ":"
  def load("presentation:" <> host) do
    {:ok, %{host: host, service: :presentation}}
  end
  def load("identity:" <> host) do
    {:ok, %{host: host, service: :identity}}
  end
  def load("repository:" <> host) do
    {:ok, %{host: host, service: :repository}}
  end
  def load("social_graph:" <> host) do
    {:ok, %{host: host, service: :social_graph}}
  end

  def dump(%{host: host, service: service}) do
    {:ok, "#{service}:#{host}"}
  end
end
