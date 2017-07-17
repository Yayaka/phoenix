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
      add :user, :string

      timestamps()
    end
    create unique_index(:user_links, [:provided_user_id, :user],
                        name: :user_links_unique_index)

    create table(:timeline_subscriptions, primary_key: false) do
      add :id, :string, primary_key: true

      add :user, :string
      add :social_graph, :string

      timestamps()
    end

    # Identity

    create table(:identity_users, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:identity_users, [:name],
                        name: :identity_users_unique_index)

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

      add :user, :string
      add :protocol, :string
      add :type, :string
      add :body, :map

      add :sender, :string
      timestamps()
    end

    # Social graph

    create table(:subscriptions) do
      add :user, :string
      add :target_user, :string
      add :social_graph, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:subscriptions, [:user, :target_user, :social_graph],
                        name: :subscriptions_unique_index)

    create table(:subscribers) do
      add :user, :string
      add :target_user, :string
      add :social_graph, :string

      add :sender, :string
      timestamps()
    end
    create unique_index(:subscribers, [:user, :target_user, :social_graph],
                        name: :subscribers_unique_index)

    create table(:timeline_subscribers, primary_key: false) do
      add :id, :string, primary_key: true
      add :identity, :string
      add :user, :string

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
      add :user, :string
      add :event_id, references(:social_graph_events)
    end
  end
end
