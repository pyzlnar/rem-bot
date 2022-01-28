defmodule Injector do
  alias Injector.{ExpectationError, Server}

  # --- Meta --- #

  defmacro __using__(opts) do
    injectors = Keyword.get(opts, :inject, [])
    quote do
      import unquote(__MODULE__), only: [stubs: 3, expects: 3, expects: 4]

      setup_all do
        servers =
          for injector <- unquote(injectors), into: %{} do
            {:ok, server} = start_supervised(Injector.Server)
            {injector, server}
          end

        %{injectors: servers}
      end

      setup %{injectors: servers} = context do
        Process.put(:injectors, servers)
        on_exit(fn ->
          Process.delete(:injectors)
          Enum.each(servers, &unquote(__MODULE__).ended/1)
        end)
        context
      end
    end
  end


  # --- Api --- #

  def expects(server, fn_name, times \\ 1, fun) do
    Server.expects(get_server(server), fn_name, times, fun)
  end

  def stubs(server, fn_name, fun) do
    Server.stubs(get_server(server), fn_name, fun)
  end

  def inject(server, fn_name, args) do
    case Server.called(get_server(server), fn_name, args) do
      {:ok, result} ->
        result
      {:error, msg} ->
        raise msg
      _ ->
        raise "There was an error calling #{fn_name}"
    end
  end

  def ended({_mod, server}) do
    case Server.ended(get_server(server)) do
      :ok ->
        :ok
      {:errors, [first_error|_]} ->
        raise ExpectationError, message: first_error
      _ ->
        raise "ONOZ"

    end
  end

  # --- Helpers --- #

  def get_server(server) when is_pid(server) do
    server
  end

  def get_server(server) when is_atom(server) do
    Process.get(:injectors)[server]
  end
end
