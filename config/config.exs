import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN", "discord_token_missing")

config :porcelain,
  driver: Porcelain.Driver.Basic

config :logger,
  level: :info

config :rem,
  commands: ~W[
    help
    ping
    repo
    wordle
  ],
  prefixes: ~W[! Rem]

config :rem,
  ecto_repos: [Rem.Repo]

config :rem, Rem.Repo,
  migration_timestamps:  [type: :utc_datetime_usec],
  migration_primary_key: [name: :id, type: :binary_id, default: {:fragment, "uuid_generate_v4()"}]

import_config "#{Mix.env()}.exs"
