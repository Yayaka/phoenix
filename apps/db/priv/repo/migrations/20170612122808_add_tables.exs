defmodule DB.Repo.Migrations.AddTables do
  use Ecto.Migration

  def change do
    # Common

    create table(:host_informations, primary_key: false) do
      add :host, :string, primary_key: true

      add :ymp_version, :string
      add :connection_protocols, :map
      add :message_protocols, :map

      timestamps
    end

    create table(:services) do
      add :host, :string
      add :protocol, :string
      add :service, :string

      timestamps
    end
    create unique_index(:services, [:host, :protocol, :service])

    create table(:users) do
      add :host, :string
      add :protocol, :string

      timestamps
    end
    create unique_index(:users, [:host, :protocol])

    # Presentaion

    create table(:provided_users) do
      add :provider, :string
      add :provided_id, :string

      timestamps
    end
    create unique_index(:provided_users, [:provider, :provided_id])

    create table(:user_links, primary_key: false) do
      add :provided_user_id,
        references(:provided_users), primary_key: true
      add :user_id, references(:users), primary_key: true

      timestamps
    end

    create table(:event_subscriptions, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :user_id, references(:users)
      add :social_graph_id, references(:services)

      timestamps
    end

    # Identity

    create table(:identity_users, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :sender_id, references(:services)
      timestamps
    end

    create table(:user_attributes, primary_key: false) do
      add :identity_user_id,
        references(:identity_users, type: :uuid), primary_key: true
      add :protocol, :string, primary_key: true
      add :key, :string, primary_key: true
      add :value, :map

      add :sender_id, references(:services)
      timestamps
    end

    create table(:authorized_services, primary_key: false) do
      add :identity_user_id,
        references(:identity_users, type: :uuid), primary_key: true
      add :service_id, references(:services), primary_key: true

      add :sender_id, references(:services)
      timestamps
    end

    # Repository

    create table(:events, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :user_id, references(:users)
      add :protocol, :string
      add :type, :string

      add :sender_id, references(:services)
      timestamps
    end

    create table(:event_parameters, primary_key: false) do
      add :event_id, references(:events, type: :uuid), primary_key: true
      add :key, :string, primary_key: true

      add :value, :map
    end

    create table(:repository_subscribers, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :social_graph_id, references(:services), primary_key: true

      add :sender_id, references(:services)
      timestamps
    end

    # Social graph

    create table(:repository_subscriptions, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :repository_id, references(:services), primary_key: true

      add :sender_id, references(:services)
      timestamps
    end

    create table(:social_graph_subscriptions, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :social_graph_id, references(:services), primary_key: true

      add :sender_id, references(:services)
      timestamps
    end

    create table(:social_graph_subscribers, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :social_graph_id, references(:services), primary_key: true

      add :sender_id, references(:services)
      timestamps
    end

    create table(:event_subscribers, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :service_id, references(:services)

      add :sender_id, references(:services)
      timestamps
    end

    create table(:event_subscriber_matchers) do
      add :event_subscriber_id, references(:event_subscribers, type: :uuid)
      add :types, {:array, :map}
    end

    create table(:event_subscriber_matcher_users) do
      add :event_subscriber_matcher_id,
        references(:event_subscriber_matchers), primary_key: true
      add :user_id, references(:users), primary_key: true
    end
  end
end
