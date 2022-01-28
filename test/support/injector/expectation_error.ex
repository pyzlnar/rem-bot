defmodule Injector.ExpectationError do
  defexception message: "A function was expected to be called a certain number of times, but wasn't"
end
