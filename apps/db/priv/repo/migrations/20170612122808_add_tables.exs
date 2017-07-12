defmodule DB.Repo.Migrations.AddTables do
  use Ecto.Migration

  def change do
    # YMP

    create table(:host_informations, primary_key: false) do
      add :host, :string, primary_key: true

      add :ymp_version, :string
      add :connection_protocols, {:array, :map}
      add :service_protocols, {:array, :map}

      timestamps()
    end

    # Yayaka

    create table(:users) do
      add :identity, :string
      add :user_id, :string

      timestamps()
    end
    create unique_index(:users, [:identity, :user_id],
                        name: :users_host_user_id_index)

    # Presentaion

    create table(:provided_users) do
      add :provider, :string
      add :provided_id, :string

      timestamps()
    end
    create unique_index(:provided_users, [:provider, :provided_id],
                        name: :provided_user_provider_provided_id_index)

    create table(:user_links) do
      add :provided_user_id, references(:provided_users)
      add :user_id, references(:users)

      timestamps()
    end
    create unique_index(:user_links, [:provided_user_id, :user_id],
                        name: :user_links_unique_index)

    create table(:event_subscriptions, primary_key: false) do
      add :id, :string, primary_key: true

      add :user_id, references(:users)
      add :social_graph, :string

      timestamps()
    end

    # Identity

    create table(:identity_users, primary_key: false) do
      add :id, :string, primary_key: true

      add :sender, :string
      timestamps()
    end

    create table(:user_attributes) do
      add :identity_user_id, references(:identity_users, type: :string)
      add :protocol, :string
      add :key, :string
      add :value, :map

      add :sender, :string
      timestamps()
    end
    create unique_index(:user_attributes, [:identity_user_id,
                                           :protocol,
                                           :key],
                        name: :user_attributes_unique_index)

    create table(:authorized_services) do
      add :identity_user_id, references(:identity_users, type: :string)
      add :service, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:authorized_services, [:identity_user_id,
                                               :service],
                        name: :authorized_services_unique_index)

    # Repository

    create table(:events, primary_key: false) do
      add :id, :string, primary_key: true

      add :user_id, references(:users)
      add :protocol, :string
      add :type, :string
      add :body, :map

      add :sender, :string
      timestamps()
    end

    create table(:contents, primary_key: false) do
      add :id, :string, primary_key: true

      add :user_id, references(:users)
      add :protocol, :string
      add :type, :string
      add :body, :map
      add :deleted, :boolean, default: false

      add :sender, :string
      timestamps()
    end

    create table(:repository_subscribers) do
      add :user_id, references(:users)
      add :social_graph, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:repository_subscribers, [:user_id, :social_graph],
                        name: :repository_subscribers_unique_index)

    # Social graph

    create table(:repository_subscriptions) do
      add :user_id, references(:users)
      add :repository, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:repository_subscriptions, [:user_id, :repository],
                        name: :repository_subscriptions_unique_index)

    create table(:social_graph_subscriptions) do
      add :user_id, references(:users)
      add :target_user_id, references(:users)
      add :social_graph, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:social_graph_subscriptions, [:user_id, :target_user_id, :social_graph],
                        name: :social_graph_subscriptions_unique_index)

    create table(:social_graph_subscribers) do
      add :user_id, references(:users)
      add :target_user_id, references(:users)
      add :social_graph, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:social_graph_subscribers, [:user_id, :target_user_id, :social_graph],
                        name: :social_graph_subscribers_unique_index)

    create table(:event_subscribers, primary_key: false) do
      add :id, :string, primary_key: true
      add :identity, :string
      add :user_id, references(:users)

      add :presentation, :string

      add :sender, :string
      timestamps()
    end

    create table(:social_graph_events) do
      add :social_graph, :string
      add :event_id, :string
      add :event, :map

      add :sender, :string
      timestamps()
    end

    create table(:timeline_events) do
      add :user_id, references(:users)
      add :event_id, references(:social_graph_events)
    end
  end
end
