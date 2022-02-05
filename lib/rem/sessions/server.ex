defmodule Rem.Sessions.Server do
  @moduledoc """
  A session is a server that can cache a term for a discord user.
  These sessions expire after a bit of inactivity, and can run a function after they close.
  """

  require Logger
  use GenServer
  import GenServer, only: [call: 2, cast: 2]

  @timeout 20 * 60 * 1000

  # -- Setup -- #

  def child_spec({session_id, opts}) do
    %{
      id:      {__MODULE__, session_id},
      start:   {__MODULE__, :start_link, [session_id, opts]},
      restart: :temporary
    }
  end

  def start_link(session_id, opts) do
    GenServer.start_link(__MODULE__, opts, name: via(session_id))
  end

  # -- API --- #

  def new(session_id, opts \\ []) do
    DynamicSupervisor.start_child(
      Rem.Session.DynamicSupervisor,
      {__MODULE__, {session_id, opts}}
    )
  end

  def get(session_id) do
    with :ok <- has_session?(session_id),
         do: {:ok, get!(session_id)}
  end

  defp get!(session_id) do
    via(session_id)
    |> call(:get)
  end

  def get_handler(session_id) do
    with :ok <- has_session?(session_id),
         do: {:ok, get_handler!(session_id)}
  end

  defp get_handler!(session_id) do
    via(session_id)
    |> call(:get_handler)
  end

  def set(session_id, value) do
    with :ok <- has_session?(session_id),
         do: {:ok, set!(session_id, value)}
  end

  defp set!(session_id, value) do
    via(session_id)
    |> call({:update, value})
  end

  def kill(session_id) do
    via(session_id)
    |> cast(:kill)
  end

  def has_session?(session_id) do
    with [{pid, _}] <- Registry.lookup(Rem.Session.Registry, session_id),
         true       <- Process.alive?(pid),
         do:   :ok,
         else: (_ -> {:error, :no_session})
  end

  defp via(session_id) do
    {
      :via,
      Registry,
      {Rem.Session.Registry, session_id}
    }
  end

  # -- Server -- #

  def init(opts) do
    state = %{
      value:      Keyword.get(opts, :value),
      handler:    Keyword.get(opts, :handler),
      timeout:    Keyword.get(opts, :timeout, @timeout),
      on_timeout: Keyword.get(opts, :on_timeout, fn -> :ok end)
    }

    {:ok, state, state.timeout}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.value, state, state.timeout}
  end

  def handle_call(:get_handler, _from, state) do
    {:reply, state.handler, state, state.timeout}
  end

  def handle_call({:update, update_fn}, _from, state) when is_function(update_fn, 1) do
    state = %{state|value: update_fn.(state.value)}
    {:reply, state.value, state, state.timeout}
  end

  def handle_call({:update, value}, _from, state) do
    state = %{state|value: value}
    {:reply, state.value, state, state.timeout}
  end

  def handle_cast(:kill, _state) do
    {:stop, :shutdown, :ok}
  end

  def handle_info(:timeout, state) do
    try do
      state.on_timeout.()
    rescue
      error ->
        Logger.warn "[#{__MODULE__}] on_timeout/0 raised: #{inspect error}"
    end

    {:stop, :normal, :ok}
  end
end
