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
  ],
  prefixes: ~W[! Rem]

import_config "#{Mix.env()}.exs"
