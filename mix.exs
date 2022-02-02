defmodule Rem.MixProject do
  use Mix.Project

  def project do
    [
      app: :rem,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: compilers()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Rem.Application, []}
    ]
  end

  # Add gettext to compilers so it recompiles when locale files change
  defp compilers, do: [:gettext] ++ Mix.compilers()

  # Load extra paths when on test
  defp elixirc_paths(:test), do: ~W[lib test/support]
  defp elixirc_paths(_), do: ~W[lib]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.7"},
      {:ecto_sql, "~> 3.2"},
      {:gettext, ">= 0.0.0"},
      {:nostrum, "~> 0.4"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
