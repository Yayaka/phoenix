defmodule Yayaka.ServiceTest do
  use ExUnit.Case

  test "cast" do
    service1 = Ecto.Type.cast(Yayaka.Service,
                              %{host: "host1", service: :repository})
    service2 = Ecto.Type.cast(Yayaka.Service,
                              %{"host" => "host1", "service" => "social-graph"})
    assert service1 == {:ok, %{host: "host1", service: "repository"}}
    assert service2 == {:ok, %{host: "host1", service: "social-graph"}}
  end

  test "dump" do
    service1 = Ecto.Type.dump(Yayaka.Service,
                              %{host: "host1", service: "repository"})
    service2 = Ecto.Type.dump(Yayaka.Service,
                              %{host: "host1", service: "social-graph"})
    service3 = Ecto.Type.dump(Yayaka.Service,
                              %{host: "host1", service: :social_graph})
    assert service1 == {:ok, "repository:host1"}
    assert service2 == {:ok, "social-graph:host1"}
    assert service3 == {:ok, "social-graph:host1"}
  end

  test "load" do
    service1 = Ecto.Type.load(Yayaka.Service, "repository:host1")
    service2 = Ecto.Type.load(Yayaka.Service, "social-graph:host1")
    assert service1 == {:ok, %{host: "host1", service: "repository"}}
    assert service2 == {:ok, %{host: "host1", service: "social-graph"}}
  end
end
