defmodule Rem.Commands.Wordle.StartCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  alias Rem.Queries.WordleQuery
  alias Rem.Sessions.WordleSession

  require Logger

  # TODO errors to message
  # TODO better board
  # TODO board prints remaining letters

  @impl true
  def run(%{author: %{id: user_id}} = msg, args) do
    with {:ok, args}    <- parse_args(args),
         :ok            <- can_start_game?(user_id, args.number),
         {:ok, game}    <- Wordle.new(args.number),
         {:ok, _record} <- WordleQuery.create_game(user_id, game),
         {:ok, _game}   <- WordleSession.new(user_id, game)
    do
      opts = game_to_message_opts(game)
      send_dm(msg, gettext("wordle:board", opts))
    else
      {:error, :invalid_arg_format} ->
        # TODO Print help message
        send_dm(msg, "Invalid command arguments")
        # run_with_args(msg, ["help"])

      {:error, :session_already_exists} ->
        send_dm(msg, "You are already playing a game!")

      {:error, :has_unfinished_game} ->
        send_dm(msg, "It seems you have an unfinished game!\nIf you'd like to resume the game use the command:\n!wordle resume")

      {:error, {:has_played_game, number}} ->
        send_dm(msg, "You have already played this game! (Wordle #{number})")

      error ->
        Logger.warn("[#{__MODULE__} #{inspect error}")
        send_dm(msg, "Something went wrong :(")
    end
  end

  # --- Helpers --- #

  defp parse_args([difficulty, id | _]) when difficulty in ~W[normal hard] do
    hard_mode? = difficulty == "hard"
    id =
      cond do
        Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, id) ->
          id |> Date.from_iso8601
        Regex.match?(~r/^\d+$/, id) ->
          id |> String.to_integer
      end

    args = %{number: Wordle.to_valid_id(id), hard: hard_mode?}

    if id,
      do:   {:ok, args},
      else: {:error, :invalid_arg_format}
  end

  defp parse_args([difficulty]) when difficulty in ~W[normal hard] do
    args =
      default_start_args()
      |> Map.put(:hard, difficulty == "hard")

    {:ok, args}
  end

  defp parse_args([]),
    do: {:ok, default_start_args()}

  defp parse_args(_other),
    do: {:error, :invalid_arg_format}

  defp default_start_args,
    do: %{number: Wordle.to_valid_id, hard: false}

  defp can_start_game?(user_id, number) do
    with :ok <- WordleSession.can_start_session?(user_id),
         :ok <- no_active_games?(user_id),
         :ok <- has_not_played_game(user_id, number)
    do
      :ok
    else
      {:error, _reason} = formated_error ->
        formated_error
      _ ->
        {:error, :cannot_start}
    end
  end

  defp no_active_games?(user_id) do
    if WordleQuery.game_exists?(user_id, state: :active),
      do:   {:error, :has_unfinished_game},
      else: :ok
  end

  defp has_not_played_game(user_id, number) do
    if WordleQuery.game_exists?(user_id, number: number),
      do:   {:error, {:has_played_game, number}},
      else: :ok
  end
end
