defmodule Rem.Jobs.SolutionFetcherTest do
  use Rem.DataCase, async: true

  import Ecto.Query

  alias Rem.Repo
  alias Rem.Jobs.SolutionFetcher
  alias Rem.Test.Mocks
  alias Schema.Wordle.Solution

  describe "perform/1" do
    test "fetches and inserts the solutions that are missing in the DB" do
      today             = Date.utc_today
      three_days_ago    = Date.add(today, -3)
      three_days_ago_id = Wordle.date_to_id(three_days_ago)

      insert(:wordle_solution, name: "lasty", number: three_days_ago_id)

      d1 = Date.add(today, -2)
      d2 = Date.add(today, -1)
      d3 = today

      Tesla.Mock.mock(&Mocks.Nytimes.fetch_solution(&1, fn %{url: url} ->
        cond do
          String.match?(url, ~r/#{Date.to_iso8601(d1)}/) ->
            %Tesla.Env{status: 200, body: %{"solution" => "first"}}

          String.match?(url, ~r/#{Date.to_iso8601(d2)}/) ->
            %Tesla.Env{status: 200, body: %{"solution" => "twice"}}

          String.match?(url, ~r/#{Date.to_iso8601(d3)}/) ->
            %Tesla.Env{status: 200, body: %{"solution" => "third"}}
        end
      end))

      assert :ok = SolutionFetcher.perform(:any)

      query =
        from ws in Solution,
        where: ws.number > ^three_days_ago_id,
        order_by: [asc: :number]

      assert [s1, s2, s3] = Repo.all(query)

      assert s1.name   == "first"
      assert s1.number == Wordle.date_to_id(d1)

      assert s2.name   == "twice"
      assert s2.number == Wordle.date_to_id(d2)

      assert s3.name   == "third"
      assert s3.number == Wordle.date_to_id(d3)
    end

    test "does nothing if the DB is already up-to-date" do
      today    = Date.utc_today
      today_id = Wordle.date_to_id(today)

      insert(:wordle_solution, name: "today", number: today_id)

      assert :ok = SolutionFetcher.perform(:any)

      query = from ws in Solution, select: count(ws.id)
      assert 1 == Repo.one(query)
    end

    test "throws an error if we're unable to retrieve a solution" do
      today        = Date.utc_today
      yesterday    = Date.add(today, -1)
      yesterday_id = Wordle.date_to_id(yesterday)

      insert(:wordle_solution, name: "yeste", number: yesterday_id)

      Tesla.Mock.mock(&Mocks.Nytimes.fetch_solution(&1, :failure))

      assert_raise(MatchError, fn -> SolutionFetcher.perform(:any) end)
    end
  end
end
