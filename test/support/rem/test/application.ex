defmodule Rem.TestApplication do
  @moduledoc """
  This application is supposed to be a mirror of Rem.Application,
  but starts dependencies only necessary for tests
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Rem.Repo,
      {Registry,          name: Rem.Session.Registry,          keys: :unique},
      {DynamicSupervisor, name: Rem.Session.DynamicSupervisor, strategy: :one_for_one},
      # Not started since it depends on Nostrum which we have off for testing
      # Rem.Consumer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
