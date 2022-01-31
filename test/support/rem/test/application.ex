# This application is supposed to be a mirror of Rem.Application,
# but start dependencies only necessary for tests
defmodule Rem.TestApplication do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Rem.Repo,
      # Not started since depends on Nostrum which we have off for testing
      # Rem.Consumer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
