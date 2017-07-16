defmodule YayakaRepository.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @event_types Application.get_env(:yayaka_repository, :event_types)
  |> Enum.map(fn {type, body} ->
    body = Enum.map(body, fn {type, body} ->
      {type, ExJsonSchema.Schema.resolve(body)}
    end) |> Enum.into(%{})
    {type, body}
  end)
  |> Enum.into(%{})

  @primary_key {:id, :string, autogenerate: false}
  schema "events" do
    belongs_to :user, Yayaka.User
    field :protocol, :string
    field :type, :string
    field :body, :map

    field :sender, Yayaka.Service
    timestamps()
  end

  @required_fields [:id, :user_id, :protocol, :type, :body, :sender]
  def changeset(event, params) do
    changeset = event
                |> cast(params, @required_fields)
                |> validate_required(@required_fields)
                |> Yayaka.EventType.validate_event_type()
                |> foreign_key_constraint(:user_id)
    validate_change(changeset, :body, fn :body, body ->
      protocol = get_field(changeset, :protocol)
      type = get_field(changeset, :type)
      schema = get_in(@event_types, [protocol, type])
      with false <- is_nil(schema),
           true <- ExJsonSchema.Validator.valid?(schema, body) do
        [] # No errors
      else
        _ ->
          [{:body, "is invalid"}]
      end
    end)
  end
end
