defmodule YMP.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @workers Application.get_env(:ymp, :workers)

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(YMP.ConnectionProvider, []),
      worker(Registry, [:unique, YMP.HTTPSTokenConnection]),
      Honeydew.queue_spec(:http),
      Honeydew.worker_spec(:http, YMP.HTTP, num: @workers[:http] || 1)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: YMP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
