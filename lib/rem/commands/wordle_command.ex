defmodule Rem.Commands.WordleCommand do
  use   Rem.Command, type: :prefix
  alias Rem.Commands.Wordle

  @impl true
  def run(msg, args) do
    run_subcommand(msg, args)
  end

  # --- Runs --- #

  defp run_subcommand(msg, args) when args in [[], ["help"]],
    do: Wordle.HelpCommand.run(msg, args)

  defp run_subcommand(msg, ["play" | args]),
    do: Wordle.StartCommand.run(msg, args)

  defp run_subcommand(msg, ["resume" | args]),
    do: Wordle.ResumeCommand.run(msg, args)

  defp run_subcommand(msg, ["stats" | args]),
    do: Wordle.StatsCommand.run(msg, args)

  defp run_subcommand(msg, args),
    do: Wordle.UnknownCommand.run(msg, args)
end
