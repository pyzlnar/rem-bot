import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN", "discord_token_missing"),
  gateway_intents: ~W[
    guilds
    guild_messages
    direct_messages
    message_content
  ]a

config :logger,
  level: :info

config :tesla,
  adapter: Tesla.Adapter.Hackney

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

config :rem, Oban,
  repo: Rem.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 7 * 24 * 60 * 60},
    {Oban.Plugins.Cron,
      crontab: [
        {"@reboot",   Rem.Jobs.SolutionFetcher, max_attempts: 1},
        {"0 1 * * *", Rem.Jobs.SolutionFetcher, max_attempts: 3}
      ]
    }
  ],
  queues: [cron: 10]

import_config "#{Mix.env()}.exs"
