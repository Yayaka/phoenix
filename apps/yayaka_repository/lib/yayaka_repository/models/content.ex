defmodule YayakaRepository.Content do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "contents" do
    belongs_to :user, Yayaka.User
    field :protocol, :string
    field :type, :string
    field :body, :map
    field :deleted, :boolean, default: false

    field :sender, Yayaka.Service
    timestamps()
  end

  @required_fields [:id, :user_id, :protocol, :type, :body, :sender]
  @fields [:deleted] ++ @required_fields
  def changeset(content, params) do
    content
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:user_id)
    |> Yayaka.ContentType.validate_content_type()
  end
end
