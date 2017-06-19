defmodule Yayaka.ContentType do
  @content_types Application.get_env(:yayaka, :content_types)

  def validate_content_type(changeset) do
    Ecto.Changeset.validate_change(changeset, :type, fn :type, type ->
      protocol = Ecto.Changeset.get_change(changeset, :protocol)
      case Map.get(@content_types, protocol) do
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
