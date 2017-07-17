defmodule YayakaSocialGraph.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    field :user, Yayaka.User
    field :target_user, Yayaka.User
    field :social_graph, Yayaka.Service

    field :sender, Yayaka.Service
    timestamps()
  end

  @fields [:user, :target_user, :social_graph, :sender]
  def changeset(social_graph_subscription, params) do
    social_graph_subscription
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> Yayaka.Service.validate_service(:social_graph, :social_graph)
    |> foreign_key_constraint(:user_id)
  end
end
