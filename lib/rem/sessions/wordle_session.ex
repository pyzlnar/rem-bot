defmodule Rem.Sessions.WordleSession do
  @moduledoc """
  Manages the session of a wordle game
  """

  use Rem.Session
  alias Rem.Discord.Api

  @impl true
  def new(user_id, game) do
    with {:ok, %{id: channel_id}} <- Api.create_dm(user_id),
         {:ok, on_timeout}        <- gen_on_timeout(channel_id)
    do
      opts = [
        handler:    Rem.Commands.Wordle.PlayCommand,
        on_timeout: on_timeout,
        value:      %{game: game, channel_id: channel_id}
      ]
      super(user_id, opts)
    end
  end

  @impl true
  def set(user_id, %Wordle.Game{} = game) do
    with {:ok, update_fn} <- gen_update_fn(game),
         {:ok, value}     <- super(user_id, update_fn),
         do: {:ok, value.game}
  end

  # --- Helpers --- #

  # TODO: gettext
  defp gen_on_timeout(channel_id) do
    {:ok, fn -> Api.create_message(channel_id, "Your session has expired!") end}
  end

  defp gen_update_fn(game) do
    {:ok, fn value -> %{value|game: game} end}
  end
end
