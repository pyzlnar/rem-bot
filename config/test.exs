import Config

config :logger,
  level: :error

config :nostrum,
  token: "test_token"

config :tesla,
  adapter: Tesla.Mock

config :rem, Rem.Discord.Api, %{
  inject: true
}

config :rem, Rem.Repo,
  username: "postgres",
  password: "postgres",
  database: "rem_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
