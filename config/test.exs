import Config

config :nostrum,
  token: "test_token"

config :rem, Rem.Discord.Api, %{
  inject: true
}

config :rem, Rem.Repo,
  username: "postgres",
  password: "postgres",
  database: "rem_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
