defmodule Rem.Session do
  @moduledoc """
  A session helps Rem maintain a "conversation" with an user, by caching data in a state.

  Both the session_id and the state can be anything you need, although using the user_id as a
  session_id is recomended.

  When you use the module, most functions are ready to be used, though you probably will need to
  override new/2 as you need to send a handler in the options.

  When a session exists, a Handler is the module that will be called by the consumer to handle the
  conversation. This module is expected to implement the `Rem.Command.SessionHandler` behvaiour.
  See `Rem.Command` for more details.
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
      alias Rem.Sessions.Server

      @impl true
      def can_start_session?(session_id) do
        with {:error, :no_session} <- has_session?(session_id),
             do: :ok,
             else: (_ -> {:error, :session_already_exists})
      end

      @impl true
      def has_session?(session_id) do
        Server.has_session?(session_id)
      end

      @impl true
      def new(session_id, opts) do
        opts = Keyword.merge([handler: Rem.Commands.NoopCommand], opts)
        Server.new(session_id, opts)
      end

      @impl true
      def get(session_id) do
        Server.get(session_id)
      end

      @impl true
      def set(session_id, value) do
        Server.set(session_id, value)
      end

      @impl true
      def kill(session_id) do
        Server.kill(session_id)
      end

      defoverridable unquote(__MODULE__)
    end
  end

  @type message       :: map
  @type session_id    :: term
  @type session_value :: term
  @type reason        :: atom

  @callback can_start_session?(session_id) :: :ok | {:error, :session_already_exists}
  @callback has_session?(session_id)       :: :ok | {:error, :no_session}
  @callback new(session_id, list)          :: :ok | {:error, reason}
  @callback get(session_id)                :: {:ok, session_value} | {:error, :no_session | reason}
  @callback set(session_id, term)          :: {:ok, session_value} | {:error, :no_session | reason}
  @callback kill(session_id)               :: :ok

  alias Rem.Sessions.Server

  @spec get_handler(session_id) :: {:ok, module} | {:error, reason}
  def get_handler(session_id) do
    Server.get_handler(session_id)
  end
end
