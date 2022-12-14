defmodule Rem.Commands.Wordle.StartCommand do
  use Rem.Command, type: :prefix

  import Rem.I18n
  import Rem.Commands.Utils

  alias Rem.Queries.WordleQuery
  alias Rem.Sessions.WordleSession

  @impl true
  def run(%{author: %{id: user_id}} = msg, args) do
    with {:ok, args}    <- parse_args(args),
         :ok            <- can_start_game?(user_id, args.number),
         {:ok, game}    <- Wordle.new(args.number, hard: args.hard),
         {:ok, _record} <- WordleQuery.create_game(user_id, game),
         {:ok, _pid}    <- WordleSession.new(user_id, game)
    do
      opts = game_to_message_opts(game)
      send_dm(msg, dgettext("wordle", "board", opts))
      :ok
    else
      error ->
        handle_error(msg, error)
        error
    end
  end

  # --- Helpers --- #

  defp parse_args([difficulty, id | _]) when difficulty in ~W[normal hard] do
    hard_mode? = difficulty == "hard"
    id =
      cond do
        Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, id) ->
          id |> Date.from_iso8601 |> elem(1) |> Wordle.date_to_id
        Regex.match?(~r/^\d+$/, id) ->
          id |> String.to_integer
      end

    case Wordle.Validator.valid_id?(id) do
      :ok -> {:ok, %{number: id, hard: hard_mode?}}
      _   -> {:error, :invalid_arg_format}
    end
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
    do: %{number: Wordle.default_id, hard: false}

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

  defp handle_error(msg, {:error, :invalid_arg_format}) do
    header  = dgettext("wordle", "error:invalid_arg_format")
    content = dgettext("wordle", "help", prefix: get_command_prefix())
    message = dgettext("wordle", "with_header", header: header, content: content)
    send_dm(msg, message)
  end

  defp handle_error(msg, {:error, :session_already_exists}) do
    send_dm(msg, dgettext("wordle", "error:session_already_exists"))
  end

  defp handle_error(msg, {:error, :has_unfinished_game}) do
    send_dm(msg, dgettext("wordle", "error:has_unfinished_game", prefix: get_command_prefix()))
  end

  defp handle_error(msg, {:error, {:has_played_game, number}}) do
    send_dm(msg, dgettext("wordle", "error:has_played_game", number: number))
  end

  defp handle_error(msg, error) do
    handle_unknown_error(__MODULE__, msg, error)
  end
end
