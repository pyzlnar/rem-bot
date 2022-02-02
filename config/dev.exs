import Config

config :rem, Rem.Repo,
  username: "postgres",
  password: "postgres",
  database: "rem_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
