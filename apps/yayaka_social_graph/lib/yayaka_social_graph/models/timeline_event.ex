defmodule YayakaSocialGraph.TimelineEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "timeline_events" do
    field :user, Yayaka.User
    belongs_to :event, YayakaSocialGraph.Event

    timestamps()
  end

  @required_fields [:user, :event_id]
  def changeset(event, params) do
    event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
