defmodule Rem.Repo do
  use Ecto.Repo,
    otp_app: :rem,
    adapter: Ecto.Adapters.Postgres
end
