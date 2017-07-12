defmodule YayakaRepository.RepositorySubscriber do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "repository_subscribers" do
    belongs_to :user, Yayaka.User
    field :social_graph, Yayaka.Service

    field :sender, Yayaka.Service
    timestamps()
  end

  @fields [:user_id, :social_graph, :sender]
  def changeset(repository_subscriber, params) do
    repository_subscriber
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:social_graph, name: :repository_subscribers_unique_index)
    |> Yayaka.Service.validate_service(:social_graph, :social_graph)
    |> foreign_key_constraint(:user_id)
  end
end
