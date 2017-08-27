defmodule Yayaka.Application do
  @moduledoc false

  use Application

  @user_information_ttl :timer.minutes(1)
  @user_name_ttl :timer.hours(24)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Cachex, [:yayaka_user, [default_ttl: @user_information_ttl]], id: :cachex_user_worker),
      worker(Cachex, [:yayaka_user_name, [default_ttl: @user_name_ttl]], id: :cachex_user_name_worker)
    ]

    opts = [strategy: :one_for_one, name: Yayaka.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
