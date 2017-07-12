defmodule YayakaSocialGraph.TimelineEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "timeline_events" do
    belongs_to :user, Yayaka.User
    belongs_to :event, YayakaSocialGraph.Event
  end

  @required_fields [:user_id, :event_id]
  def changeset(event, params) do
    event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
