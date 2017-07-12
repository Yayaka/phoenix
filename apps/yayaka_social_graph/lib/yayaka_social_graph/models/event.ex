defmodule YayakaSocialGraph.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "social_graph_events" do
    field :social_graph, Yayaka.Service
    field :event_id, :string
    field :event, :map

    field :sender, Yayaka.Service
    timestamps()
  end

  @required_fields [:social_graph, :event_id, :event, :sender]
  def changeset(event, params) do
    event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> Yayaka.Service.validate_service(:social_graph, :social_graph)
  end
end
