defmodule Rem.Commands.WordleCommand do
  @behaviour Rem.Commands.Command

  import Rem.I18n
  alias Rem.Discord.Api
  alias Rem.Queries.WordleQuery
  alias Rem.Sessions.WordleSession

  require Logger

  def run(msg, args_str) do
    run_with_args(msg, parse_args(args_str))
  end

  # --- Runs --- #

  defp run_with_args(msg, [str]) when str in ["", "help"] do
    prefix = Application.get_env(:rem, :prefixes, ["<prefix>"]) |> hd

    send_dm(msg, gettext("wordle:help", prefix: prefix))
  end

  # TODO errors to message
  # TODO better board
  # TODO board prints remaining letters
  defp run_with_args(%{author: %{id: user_id}} = msg, ["play" | rest]) do
    with {:ok, args}    <- parse_start_args(rest),
         :ok            <- can_start_game?(user_id, args.number),
         {:ok, game}    <- new_game(args.number),
         {:ok, _record} <- persist_game(user_id, game),
         {:ok, _game}   <- start_session(user_id, game)
    do
      board = game_to_board(game)
      nrow  = length(game.attempts)
      board = "#{board}\n _  _  _  _  _ "

      send_dm(msg, gettext("wordle:board", number: game.number, board: board, attempt: nrow))
    else
      {:error, :invalid_arg_format} ->
        send_dm(msg, "Invalid command arguments")
        run_with_args(msg, ["help"])

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

  defp run_with_args(%{author: %{id: user_id}} = msg, ["resume"]) do
    with :ok                            <- WordleSession.can_start_session?(user_id),
         record when not is_nil(record) <- WordleQuery.fetch_game(user_id, state: :active),
         {:ok, game}                    <- Rem.Wordle.from_record(record),
         {:ok, _game}                   <- start_session(user_id, game)
    do
      board = game_to_board(game)
      nrow  = length(game.attempts)
      board = "#{board}\n _  _  _  _  _  _"

      send_dm(msg, gettext("wordle:board", number: game.number, board: board, attempt: nrow))
    end
  end

  defp run_with_args(_args, _msg) do
    :noop
  end

  # --- Helpers --- #

  defp parse_args(args_str) do
    args_str
    |> String.split(~r/\s+/)
  end

  defp parse_start_args([difficulty, id | _]) when difficulty in ~W[normal hard] do
    hard_mode? = difficulty == "hard"
    id =
      cond do
        Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, id) ->
          id |> Date.from_iso8601 |> Rem.Wordle.to_valid_id
        Regex.match?(~r/^\d+$/, id) ->
          id |> String.to_integer
      end

    args = %{number: Rem.Wordle.to_valid_id(id), hard: hard_mode?}

    if id,
      do:   {:ok, args},
      else: {:error, :invalid_arg_format}
  end

  defp parse_start_args([difficulty]) when difficulty in ~W[normal hard] do
    args =
      default_start_args()
      |> Map.put(:hard, difficulty == "hard")

    {:ok, args}
  end

  defp parse_start_args([]),
    do: {:ok, default_start_args()}

  defp parse_start_args(_other),
    do: {:error, :invalid_arg_format}

  defp default_start_args,
    do: %{number: Rem.Wordle.to_valid_id, hard: false}

  defp send_dm(%{author: %{id: user_id}}, message) do
    with {:ok, %{id: channel_id}} <- Api.create_dm(user_id),
         {:ok, _}                 <- Api.create_message(channel_id, message),
         do: :ok
  end

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

  defp new_game(number) do
    Rem.Wordle.new(number)
  end

  defp persist_game(user_id, game) do
    WordleQuery.create_game(user_id, game)
  end

  # TODO gettext
  defp start_session(user_id, game) do
    WordleSession.new(user_id, game)
  end

  # TODO: This can be prettier...
  def game_to_board(game) do
    Stream.zip(game.attempts, game.evaluations)
    |> Stream.map(fn {attempt, evaluation} ->
      attempt
      |> String.graphemes
      |> Enum.zip(evaluation)
      |> Enum.map(fn
        {char, :absent}  -> "-#{char}-"
        {char, :present} -> "~#{char}~"
        {char, :correct} -> "[#{char}]"
      end)
      |> Enum.join(" ")
    end)
    |> Enum.reverse
    |> Enum.join("\n")
  end
end
