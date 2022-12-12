defmodule Rem.MixProject do
  use Mix.Project

  def project do
    [
      app:             :rem,
      version:         "0.1.0",
      elixir:          "~> 1.13",
      elixirc_paths:   elixirc_paths(Mix.env),
      aliases:         aliases(),
      compilers:       compilers(),
      deps:            deps(),
      start_permanent: Mix.env == :prod,
      test_coverage:   coverage(),
      xref:            xref_excludes(Mix.env)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications:       applications(Mix.env),
      extra_applications: [:logger],
      mod:                mod(Mix.env)
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  # Returns the applications to load before starting :rem
  # Defaults to all deps with runtime: true
  # On test we remove hard-to-test apps and test with workarounds
  defp applications(:test) do
    applications(:dev) -- [:nostrum]
  end

  defp applications(_normal) do
    deps()
    |> Enum.filter(fn
      {_, _, opts} -> Keyword.get(opts, :runtime, true)
      _            -> true
    end)
    |> Enum.map(&(elem(&1, 0)))
  end

  # Returns the module to start the app's supervision tree
  defp mod(:test),   do: {Rem.TestApplication, []}
  defp mod(_normal), do: {Rem.Application, []}

  # Add gettext to compilers so it recompiles when locale files change
  defp compilers, do: [:gettext] ++ Mix.compilers()

  defp coverage do
    [
      ignore_modules: [
        Rem.DataCase,
        ~r/^Rem\.Test/,
        ~r/^Injector/,
      ]
    ]
  end

  # Load extra paths when on test
  defp elixirc_paths(:test),   do: ~W[lib test/support]
  defp elixirc_paths(_normal), do: ~W[lib]

  # Removes warnings for Nostrum not being started in test
  defp xref_excludes(:test), do: [exclude: Nostrum.Consumer]
  defp xref_excludes(_),     do: nil

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    deps(:normal) ++ deps(Mix.env)
  end

  defp deps(:normal) do
    [
      {:ecto,     "~> 3.9"},
      {:ecto_sql, "~> 3.9"},
      {:gettext,  ">= 0.0.0"},
      {:nostrum,  "~> 0.6"},
      {:postgrex, ">= 0.0.0"}
    ]
  end

  defp deps(:test) do
    [
      {:ex_machina, "~> 2.7.0", only: :test}
    ]
  end

  defp deps(_other), do: []
end
