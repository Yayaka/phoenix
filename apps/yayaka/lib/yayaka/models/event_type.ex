defmodule Yayaka.EventType do
  @event_types Application.get_env(:yayaka, :event_types)

  def validate_event_type(changeset) do
    Ecto.Changeset.validate_change(changeset, :type, fn :type, type ->
      protocol = Ecto.Changeset.get_change(changeset, :protocol)
      case Map.get(@event_types, protocol) do
        types when not is_nil(types) ->
          if type in types do
            [] # No errors
          else
            [{:type, "is invalid"}]
          end
        _ -> [{:protocol, "is invalid"}]
      end
    end)
  end
end
