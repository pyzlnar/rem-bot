defmodule Rem.Discord.Api do
  @moduledoc """
  This module acts as a wrapper for Nostrum.Api
  The sole purpose of this module is to be able to write tests
  """

  module = Nostrum.Api

  for {name, arity} <- module.__info__(:functions) do
    args = 1..arity |> Enum.map(& Macro.var(:"arg#{&1}", __MODULE__))

    if Application.get_env(:rem, __MODULE__)[:inject] do
      def unquote(name)(unquote_splicing(args)) do
        Injector.inject(__MODULE__, unquote(name), unquote(args))
      end
    else
      def unquote(name)(unquote_splicing(args)) do
        apply(unquote(module), unquote(name), unquote(args))
      end
    end
  end
end
