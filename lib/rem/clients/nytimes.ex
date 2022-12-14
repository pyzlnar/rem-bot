defmodule Rem.Clients.Nytimes do
  use Tesla

  alias Tesla.Middleware, as: T
  alias Rem.Clients.Middleware, as: R

  plug T.BaseUrl, "https://www.nytimes.com/svc/wordle/v2"

  plug R.Unpack
  plug T.JSON
  plug R.ExpectedStatus, [200]

  if Mix.env != :test, do:
    plug T.Logger

  @spec fetch_solution(Date.t) :: {:ok, String.t} | {:error, term}

  def fetch_solution(%Date{} = date) do
    iso_date = Date.to_iso8601(date)

    case get("/#{iso_date}.json") do
      {:ok, %{"solution" => solution}} ->
        {:ok, solution}

      error ->
        error
    end
  end
end
