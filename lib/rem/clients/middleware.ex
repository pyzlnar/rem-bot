defmodule Rem.Clients.Middleware do
  # Returns {:error, term} if the received status is not in the expected status
  #
  # plug ExpectedStatus, [200, 202, 204]
  defmodule ExpectedStatus do
    @behaviour Tesla.Middleware

    @default 200..299

    @impl Tesla.Middleware
    def call(env, next, plug_status) do
      with {:ok, env} <- Tesla.run(env, next),
           :ok        <- check_status(env, plug_status)
      do
        {:ok, env}
      end
    end

    # Validate against the first expected status of
    # - This request
    # - Configured in the plug
    # - Default
    defp check_status(env, plug_status) do
      [env.opts[:status], plug_status, @default]
      |> Enum.find(fn
        [_|_]    -> true
        %Range{} -> true
        _        -> false
      end)
      |> then(fn expected_statuses ->
        if env.status in expected_statuses do
          :ok
        else
          {:error, %{reason: :unexpected_status, status: env.status, body: env.body}}
        end
      end)
    end
  end

  # If the request is succesful, returns only the body instead of the whole Tesla.Env
  defmodule Unpack do
    @behaviour Tesla.Middleware

    @impl Tesla.Middleware
    def call(env, next, _opts) do
      case Tesla.run(env, next) do
        {:ok, %Tesla.Env{body: body}} -> {:ok, body}
        {:error, _} = error           -> error
      end
    end
  end
end
