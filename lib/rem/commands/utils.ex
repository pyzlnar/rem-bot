defmodule Rem.Commands.Utils do
  @moduledoc """
  Library with common helpers for diverse commands
  """

  import Rem.I18n
  alias  Rem.Discord.Api

  require Logger

  @spec get_command_prefixes() :: [String.t]
  def get_command_prefixes do
    Application.get_env(:rem, :prefixes, ["<prefix>"])
  end

  @spec get_command_prefix() :: String.t
  def get_command_prefix do
    get_command_prefixes()
    |> hd
  end

  @spec send_dm(map, String.t) :: :ok
  def send_dm(%{author: %{id: user_id}}, message) do
    with {:ok, %{id: channel_id}} <- Api.create_dm(user_id),
         {:ok, _}                 <- Api.create_message(channel_id, message),
         do: :ok
  end

  def handle_unknown_error(module, channel_id, error) when is_integer(channel_id) do
    Logger.warn("[#{module}] #{inspect error}")
    Api.create_message(channel_id, gettext("error:unknown"))
  end

  def handle_unknown_error(module, msg, error) do
    Logger.warn("[#{module}] #{inspect error}")
    send_dm(msg, gettext("error:unknown"))
  end

  def game_to_message_opts(game) do
    Wordle.Pretty.board_with_info(game)
  end
end
