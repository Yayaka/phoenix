defmodule YayakaSocialGraph.TimelineSubscriber do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "timeline_subscribers" do
    field :identity, Yayaka.Service
    belongs_to :user, Yayaka.User
    field :presentation, Yayaka.Service

    field :sender, Yayaka.Service
    timestamps()
  end

  @fields [:id, :identity, :user_id, :presentation, :sender]
  def changeset(event_subscriber, params) do
    event_subscriber
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> Yayaka.Service.validate_service(:presentation, :presentation)
  end
end
