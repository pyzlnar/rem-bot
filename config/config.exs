import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN", "discord_token_missing")

config :porcelain,
  driver: Porcelain.Driver.Basic

config :logger,
  level: :info

import_config "#{Mix.env()}.exs"
