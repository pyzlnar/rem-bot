defmodule Rem.Test.Mocks do
  defmodule Nytimes do
    @base_url "https://www.nytimes.com/svc/wordle/v2"
    def fetch_solution(%{method: :get, url: @base_url <> _} = req, action \\ :success) do
      case action do
        :success -> get_success_response()
        :failure -> get_failure_response()
        func when is_function(func) -> func.(req)
      end
    end

    defp get_success_response do
      %Tesla.Env{
        method: :get,
        status: 200,
        body:   %{
          "id"                => 1168,
          "solution"          => "apply",
          "print_date"        => "2022-12-12",
          "days_since_launch" => 541,
          "editor"            => "Someone"
        }
      }
    end

    defp get_failure_response do
      %Tesla.Env{
        method: :get,
        status: 404,
        body:   %{
          "status"  => "ERROR",
          "errors"  => ["Not Found"],
          "results" => []
        }
      }
    end
  end
end
