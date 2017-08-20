defmodule M2XNerves.Application do
  use Application

  alias M2XNerves.InputMonitor
  alias M2XNerves.M2X
  alias M2XNerves.Network

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(InputMonitor, []),
      worker(M2X, []),
      worker(Network, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: M2XNerves.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
