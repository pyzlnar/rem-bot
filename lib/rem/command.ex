defmodule Rem.Command do
  @moduledoc """
  A command processes a message directed at the bot.

  There are two behaviours that a command can implement: PrefixCommand and SessionHandler

  A PrefixCommand should be called to handle commands in the form `{prefix}{command}{args}`

  ```
  defmodule MyPrefixCommand
    use Rem.Command,
      type: :prefix
  end
  ```

  A SessionHandler is used to handle commands that can span several messages by using a session to
  cache data relevant to the conversation.

  ```
  defmodule MySessionHandler
    use Rem.Command,
      type: :session
  end
  ```
  """

  defmacro __using__(opts) do
    opts
    |> Keyword.get(:type)
    |> generate_for_type
  end

  defp generate_for_type(:prefix) do
    behaviour = Module.concat(__MODULE__, PrefixCommand)
    quote do
      @behaviour unquote(behaviour)

      @impl true
      def run(_message, _args),
        do: :noop

      defoverridable unquote(behaviour)
    end
  end

  defp generate_for_type(:session) do
    behaviour = Module.concat(__MODULE__, SessionHandler)
    quote do
      @behaviour unquote(behaviour)

      @impl true
      def should_run?(_message),
        do: :noop

      @impl true
      def run(_message, _state),
        do: :noop

      defoverridable unquote(behaviour)
    end
  end

  defp generate_for_type(_) do
    raise "[#{__MODULE__}] When using, please specify the type of command. [type: :prefix | :session]"
  end
end

defmodule Rem.Command.PrefixCommand do
  @type message :: map
  @type args    :: [String.t]

  @callback run(message, args) :: :ok | :noop | {:error, term}
end

defmodule Rem.Command.SessionHandler do
  @type message :: map
  @type state   :: term

  @callback should_run?(message) :: {:ok, state} | :noop
  @callback run(message, state)  :: :ok | {:error, term}
end
