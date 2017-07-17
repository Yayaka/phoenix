defmodule YayakaPresentation.TimelineSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "timeline_subscriptions" do
    field :user, Yayaka.User
    field :social_graph, Yayaka.Service

    timestamps()
  end

  @fields [:id, :user, :social_graph]
  def changeset(event_subscription, params) do
    event_subscription
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> Yayaka.Service.validate_service(:social_graph, :social_graph)
  end
end
