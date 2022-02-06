defmodule Rem.Consumer do
  use Nostrum.Consumer
  use Rem.Consumer.Meta

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    with :noop <- maybe_run_command(message) do
      maybe_respond_session(message)
    end
  end

  def handle_event(_other),
    do: :noop

  # --- Helpers --- #

  defp maybe_run_command(%{content: content} = message) do
    with {:ok, rest}      <- extract_prefix(content),
         {:ok, cmd, args} <- extract_command(rest)
    do
      cmd.run(message, args)
      :ok
    else
      _ -> :noop
    end
  end

  defp maybe_respond_session(%{author: %{id: user_id}} = message) do
    with {:ok, handler} <- Rem.Session.get_handler(user_id),
         {:ok, state}   <- handler.should_run?(message)
    do
      handler.run(message, state)
      :ok
    else
      _ -> :noop
    end
  end

  defp parse_args(args_str) do
    args_str
    |> String.trim
    |> String.split(~r/\s+/)
    |> Enum.reject(&(&1 == ""))
  end
end
