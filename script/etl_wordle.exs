# Run as:
# mix run script/etl_wordle.exs
#
# Requires these files to exist and to end with a newline
# - tmp/wordle/words.txt
# - tmp/wordle/solutions.txt
defmodule Etl do
  @solutions     "tmp/wordle/solutions.txt"
  @words         "tmp/wordle/words.txt"
  @all_words     "tmp/wordle/all_words.txt"

  @all_words_sql "tmp/wordle/wordle_words.sql"
  @solutions_sql "tmp/wordle/solutions.sql"

  def run do
    prepare_workspace()
    extract()
    transform()
    load()
  end

  def extract do
    extract_all_words_txt()
  end

  def transform do
    transform_solutions_sql()
    transform_all_words_sql()
  end

  def load do
    load_solutions_sql()
    load_all_words_sql()
  end

  def prepare_workspace() do
    :os.cmd('rm -f #{@all_words}')
    :os.cmd('rm -f #{@all_words_sql}')
    :os.cmd('rm -f #{@solutions_sql}')
  end

  def extract_all_words_txt do
    :os.cmd('cat #{@solutions} #{@words} | sort > #{@all_words}')
  end

  def transform_solutions_sql do
    {last_word, 0} = System.cmd("tail", ["-n 1", @solutions])
    last_word      = String.trim(last_word)

    {:ok, output} = File.open(@solutions_sql, [:write])

    try do
      now = DateTime.utc_now

      IO.write(output, "INSERT INTO wordle_solutions(name, number, inserted_at, updated_at) VALUES\n")

      @solutions
      |> File.stream!
      |> Stream.with_index
      |> Stream.each(fn {word, index} ->
        word = String.trim(word)
        last_char = if word == last_word, do: ";", else: ","

        IO.write(output, "('#{word}', #{index}, '#{now}', '#{now}')#{last_char}\n")
      end)
      |> Stream.run
    after
      File.close(@solutions_sql)
    end
  end

  def transform_all_words_sql do
    {last_word, 0} = System.cmd("tail", ["-n 1", @all_words])
    last_word      = String.trim(last_word)

    {:ok, output} = File.open(@all_words_sql, [:write])

    try do
      now = DateTime.utc_now

      IO.write(output, "INSERT INTO wordle_words(name, inserted_at, updated_at) VALUES\n")

      @all_words
      |> File.stream!
      |> Stream.each(fn word ->
        word = String.trim(word)
        last_char = if word == last_word, do: ";", else: ","

        IO.write(output, "('#{word}', '#{now}', '#{now}')#{last_char}\n")
      end)
      |> Stream.run
    after
      File.close(@all_words_sql)
    end
  end

  def load_solutions_sql do
    sql_run_command('TRUNCATE wordle_solutions')
    sql_run_command('VACUUM wordle_solutions')
    sql_run_file(@solutions_sql)
  end

  def load_all_words_sql do
    sql_run_command('TRUNCATE wordle_words')
    sql_run_command('VACUUM wordle_words')
    sql_run_file(@all_words_sql)
  end

  # --- SQL --- #

  defp sql_config do
    Application.get_env(:rem, Rem.Repo)
    |> Keyword.take(~W[username password database hostname]a)
    |> Enum.into(%{})
  end

  defp sql_with_config do
    config = sql_config()
    'export PGPASSWORD=#{config.password}; psql -U #{config.username} -d #{config.database} -h #{config.hostname}'
  end

  defp sql_run_command(command) do
    :os.cmd('#{sql_with_config()} -c "#{command}"')
  end

  defp sql_run_file(file) do
    :os.cmd('#{sql_with_config()} -f #{file}')
  end
end

Etl.run
