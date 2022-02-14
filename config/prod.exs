import Config

config :rem, Rem.Repo,
  username: System.fetch_env("DB_USERNAME"),
  password: System.fetch_env("DB_PASSWORD"),
  database: System.fetch_env("DB_DATABASE"),
  hostname: System.fetch_env("DB_HOSTNAME"),
  pool_size: 10
