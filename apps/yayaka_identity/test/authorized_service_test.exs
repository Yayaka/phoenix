defmodule YayakaIdentity.AuthorizedServiceTest do
  use ExUnit.Case
  import Ecto.Changeset
  alias YayakaIdentity.AuthorizedService

  test "valid changeset" do
    service = %{host: "host1", service: :presentation}
    sender = %{host: "host1", service: :presentation}
    params = %{
      identity_user_id: "user1",
      service: service,
      sender: sender
    }
    changeset = AuthorizedService.changeset(%AuthorizedService{}, params)
    assert changeset.valid?
    assert get_change(changeset, :identity_user_id) == "user1"
    assert get_change(changeset, :service) == service
    assert get_change(changeset, :sender) == sender
  end

  test "invalid changeset" do
    params = %{}
    changeset = AuthorizedService.changeset(%AuthorizedService{}, params)
    refute changeset.valid?
  end
end
