defmodule Rem.Clients.NytimesTest do
  use ExUnit.Case, async: true

  alias Rem.Clients.Nytimes
  alias Rem.Test.Mocks

  describe "fetch_solution/1" do
    test "returns {:ok, solution} when successful" do
      Tesla.Mock.mock(&Mocks.Nytimes.fetch_solution/1)

      {:ok, date} = Date.new(2022, 1, 1)
      assert {:ok, res} = Nytimes.fetch_solution(date)
      assert res == "apply"
    end

    test "returns {:error, term} if something goes wrong" do
      Tesla.Mock.mock(&Mocks.Nytimes.fetch_solution(&1, :failure))

      {:ok, date} = Date.new(2022, 1, 1)
      assert {:error, %{reason: :unexpected_status}} = Nytimes.fetch_solution(date)
    end
  end
end
