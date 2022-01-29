defmodule Injector.Server do
  use GenServer
  import GenServer, only: [call: 2]

  # --- Startup --- #

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  # --- API --- #

  def expects(server, name, times \\ 1, fun) do
    call(server, {:register, name, times, fun})
  end

  def stubs(server, name, fun) do
    call(server, {:register, name, :infinite, fun})
  end

  def called(server, name, args) do
    call(server, {:called, name, args})
  end

  def ended(server) do
    call(server, :ended)
  end

  # --- Server --- #

  def init(state),
    do: {:ok, state}

  def handle_call({:register, name, :infinite, fun}, _from, state) do
    state = Map.put(state, name, %{function: fun})
    {:reply, :ok, state}
  end

  def handle_call({:register, name, times, fun}, _from, state) do
    state = Map.put(state, name, %{function: fun, times: times, called: 0})
    {:reply, :ok, state}
  end

  def handle_call({:called, name, args}, _from, state) do
    with {:ok, register} <- get_registered_function(state, name),
         {:ok, result}   <- safely_call_function(register, args),
         register        <- get_new_register(register)
    do
      state = Map.put(state, name, register)
      {:reply, {:ok, result}, state}
    else
      {:error, _} = reply ->
        {:reply, reply, state}
      other ->
        {:reply, {:error, "There was an error:\n#{inspect(other)}"}, state}
    end
  end

  def handle_call(:ended, _from, state) do
    reply = all_expectations_called?(state)

    {:reply, reply, %{}}
  end

  # --- Helpers --- #

  def get_registered_function(state, name) do
    case state[name] do
      nil ->
        {:error, "Function '#{name}' was called but a stub not been registered"}
      register ->
        {:ok, register}
    end
  end

  def safely_call_function(%{function: fun}, args) do
    try do
      result = apply(fun, args)
      {:ok, result}
    rescue
      # TODO: See how feasable it is to get and parse the clauses.
      # Won't be easy but visually worth it.
      error in [FunctionClauseError] ->
        {:error, %{error|args: args}}
      error ->
        {:error, error}
    end
  end

  def get_new_register(%{times: _, called: _} = register) do
    %{register| called: register.called + 1}
  end

  def get_new_register(register) do
    register
  end

  def all_expectations_called?(state) do
    case Enum.reject(state, &expectation_complete?/1) do
      [] ->
        :ok
      failed_expectations  ->
        errors = Enum.map(failed_expectations, &expectation_to_error/1)
        {:errors, errors}
    end
  end

  def expectation_complete?({_, %{times: times, called: called}}) when times != called, do: false
  def expectation_complete?(_), do: true

  def expectation_to_error({name, %{times: times, called: 0}}) do
    "Function #{name} was expected to be called #{times} times, but was not called."
  end

  def expectation_to_error({name, %{times: times, called: called}}) do
    "Function #{name} was expected to be called #{times} times, but was called #{called} times."
  end
end
