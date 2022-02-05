defmodule Rem.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Rem.Repo,
      {Registry,          name: Rem.Session.Registry,          keys: :unique},
      {DynamicSupervisor, name: Rem.Session.DynamicSupervisor, strategy: :one_for_one},
      Rem.Consumer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
