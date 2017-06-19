defmodule YayakaSocialGraph.RepositorySubscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "repository_subscriptions" do
    belongs_to :user, Yayaka.User
    field :repository, Yayaka.Service

    field :sender, Yayaka.Service
    timestamps()
  end

  @fields [:user_id, :repository, :sender]
  def changeset(repository_subscription, params) do
    repository_subscription
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> Yayaka.Service.validate_service(:repository, :repository)
    |> foreign_key_constraint(:user_id)
  end
end
