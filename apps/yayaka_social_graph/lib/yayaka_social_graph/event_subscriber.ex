defmodule YayakaSocialGraph.EventSubscriber do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Matcher do
    use Ecto.Schema

    defmodule Type do
      use Ecto.Schema
      schema "event_subscriber_matcher_types" do
        belongs_to :event_subscriber_matcher, YayakaSocialGraph.EventSubscriber.Matcher
        field :protocol, :string
        field :type, :string
      end

      @required_fields [:protocol, :type]
      @fields [:event_subscriber_matcher_id] ++ @required_fields
      def changeset(type, params) do
        type
        |> cast(params, @fields)
        |> validate_required(@required_fields)
        |> unique_constraint(:type, name: :event_subscriber_matcher_types_index)
        |> foreign_key_constraint(:event_subscriber_matcher_id)
        |> Yayaka.EventType.validate_event_type()
      end
    end

    defmodule User do
      use Ecto.Schema
      schema "event_subscriber_matcher_users" do
        belongs_to :event_subscriber_matcher, YayakaSocialGraph.EventSubscriber.Matcher
        belongs_to :user, Yayaka.User
      end

      @required_fields [:user_id]
      @fields [:event_subscriber_matcher_id] ++ @required_fields
      def changeset(type, params) do
        type
        |> cast(params, @fields)
        |> validate_required(@required_fields)
        |> unique_constraint(:user_id, name: :event_subscriber_matcher_users_index)
        |> foreign_key_constraint(:event_subscriber_matcher_id)
        |> foreign_key_constraint(:user_id)
      end
    end

    schema "event_subscriber_matchers" do
      belongs_to :event_subscriber, YayakaSocialGraph.EventSubscriber
      has_many :types, Type
      has_many :users, User
    end

    @fields [:event_subscriber_id]
    def changeset(matcher, params) do
      matcher
      |> cast(params, @fields)
      |> cast_assoc(:types)
      |> cast_assoc(:users)
      |> foreign_key_constraint(:event_subscriber_id)
    end
  end

  @primary_key {:id, :string, autogenerate: false}
  schema "event_subscribers" do
    field :presentation, Yayaka.Service
    has_many :matchers, Matcher, references: :id

    field :sender, Yayaka.Service
    timestamps()
  end

  @fields [:id, :presentation, :sender]
  def changeset(event_subscriber, params) do
    event_subscriber
    |> cast(params, @fields)
    |> cast_assoc(:matchers)
    |> validate_required(@fields)
    |> Yayaka.Service.validate_service(:presentation, :presentation)
  end
end
