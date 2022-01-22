defmodule RemTest do
  use ExUnit.Case
  doctest Rem

  test "greets the world" do
    assert Rem.hello() == :world
  end
end
