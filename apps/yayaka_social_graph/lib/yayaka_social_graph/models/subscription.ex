defmodule YayakaSocialGraph.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    belongs_to :user, Yayaka.User
    belongs_to :target_user, Yayaka.User
    field :social_graph, Yayaka.Service

    field :sender, Yayaka.Service
    timestamps()
  end

  @fields [:user_id, :target_user_id, :social_graph, :sender]
  def changeset(social_graph_subscription, params) do
    social_graph_subscription
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> Yayaka.Service.validate_service(:social_graph, :social_graph)
    |> foreign_key_constraint(:user_id)
  end
end