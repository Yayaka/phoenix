defmodule YayakaSocialGraph.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "social_graph_events" do
    field :repository, Yayaka.Service
    field :event_id, :string
    field :event, :map

    field :sender, Yayaka.Service
  end

  @required_fields [:repository, :event_id, :event, :sender]
  def changeset(event, params) do
    event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> Yayaka.Service.validate_service(:repository, :repository)
  end
end
