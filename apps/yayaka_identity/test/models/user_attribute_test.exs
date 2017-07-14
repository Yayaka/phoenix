defmodule YayakaIdentity.UserAttributeTest do
  use DB.DataCase
  import Ecto.Changeset
  alias YayakaIdentity.UserAttribute

  test "yayaka service-labels" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "service-labels",
      value: %{"labels" => [%{
                          "host" => "host1",
                          "service" => "presentation",
                          "label" => "temporary"}]},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "service-labels",
      value: %{"labels" => [%{
                          "host" => "host1",
                          "service" => "unknown",
                          "label" => "temporary"}]},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka subscriber-hosts" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "subscriber-hosts",
      value: %{"hosts" => ["host1"]},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "subscriber-hosts",
      value: %{"hosts" => [1, 2, 3]},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka publisher-hosts" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "publisher-hosts",
      value: %{"hosts" => ["host1"]},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "publisher-hosts",
      value: %{"hosts" => [1, 2, 3]},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka primary-publisher-host" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "primary-publisher-host",
      value: %{"host" => "host1"},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "primary-publisher-host",
      value: %{"host" => 0},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka primary-repository-host" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "primary-repository-host",
      value: %{"host" => "host1"},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "primary-repository-host",
      value: %{"host" => 0},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka primary-notification-host" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "primary-notification-host",
      value: %{"host" => "host1"},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "primary-notification-host",
      value: %{"host" => 0},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka repository-subscriptions" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "repository-subscriptions",
      value: %{"subscriptions" => [%{
                          "repository-host" => "host1",
                          "social-graph-host" => "host2"}]},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "repository-subscriptions",
      value: %{"subscriptions" => [%{
                          "repository-host" => 0,
                          "social-graph-host" => 1}]},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka biography" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "biography",
      value: %{"text" => "bio"},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "biography",
      value: %{"text" => 0},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka links" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "links",
      value: %{"urls" => [%{"url" => "http://example.com",
                            "label" => "example"}]},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "links",
      value: %{"urls" => [%{"url" => "http://example.com",
                            "label" => 0}]},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka icon" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "icon",
      value: %{"url" => "http://example.com/icon.png"},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "icon",
      value: %{"url" => 0},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end

  test "yayaka name" do
    valid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "name",
      value: %{"text" => "bio"},
      sender: %{host: "host1", service: :presentation}
    }
    invalid = %{
      identity_user_id: "0",
      protocol: "yayaka",
      key: "name",
      value: %{"text" => 0},
      sender: %{host: "host1", service: :presentation}
    }
    assert UserAttribute.changeset(%UserAttribute{}, valid).valid?
    refute UserAttribute.changeset(%UserAttribute{}, invalid).valid?
  end
end
