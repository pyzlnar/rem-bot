defmodule Rem.Consumer.Meta do
  defmacro __using__(_) do
    quote do
      unquote(generate_extract_prefix())
      unquote(generate_extract_command())
    end
  end

  def generate_extract_prefix do
    quote do
      @spec extract_prefix(binary) :: {:ok, binary} | :error
      unquote(generate_extract_prefix_from_config())

      def extract_prefix(_other), do: :error
    end
  end

  defp generate_extract_prefix_from_config do
    for prefix <- Application.get_env(:rem, :prefixes, []) do
      quote do
        def extract_prefix(unquote(prefix) <> command), do: {:ok, String.trim(command)}
      end
    end
  end

  def generate_extract_command do
    quote do
      @spec extract_command(binary) :: {:ok, binary, list} |  :error
      unquote(generate_extract_command_from_config())

      def extract_command(_), do: :error
    end
  end

  defp generate_extract_command_from_config do
    for command <- Application.get_env(:rem, :commands, []) do
      command_suffix = command |> String.capitalize |> Kernel.<>("Command")
      command_alias  = Module.concat(Rem.Commands, command_suffix)

      quote do
        def extract_command(unquote(command) <> args),
          do: {:ok, unquote(command_alias), String.trim(args)}
      end
    end
  end
end
