import Config

config :nostrum,
  token: "test_token"

config :rem, Rem.Discord.Api, %{
  inject: true
}
