defmodule Rem.DataCase do
  use ExUnit.CaseTemplate

  using _opts do
    quote do
      alias Rem.Repo

      import Ecto
      import Ecto.Query
      import Rem.DataCase
      import Rem.Test.Factory
      import Rem.Test.Scenario
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rem.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rem.Repo, {:shared, self()})
    end

    :ok
  end
end
