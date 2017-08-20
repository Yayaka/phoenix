defmodule YayakaIdentity.AuthorizedServiceTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaIdentity.AuthorizedService

  test "valid changeset" do
    {:ok, identity_user} = %YayakaIdentity.IdentityUser{
      id: "user1",
      sender: %{host: "host1", service: :presentation}
    } |> DB.Repo.insert
    service = %{host: "host1", service: "presentation"}
    sender = %{host: "host1", service: "presentation"}
    params = %{
      identity_user_id: identity_user.id,
      service: service,
      sender: sender
    }
    changeset = AuthorizedService.changeset(%AuthorizedService{}, params)
    assert changeset.valid?
    assert get_change(changeset, :identity_user_id) == identity_user.id
    assert get_change(changeset, :service) == service
    assert get_change(changeset, :sender) == sender
    assert match? {:ok, _}, DB.Repo.insert(changeset)
  end

  test "invalid changeset" do
    params = %{}
    changeset = AuthorizedService.changeset(%AuthorizedService{}, params)
    refute changeset.valid?
  end
end
