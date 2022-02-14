defmodule Wordle.EmojiTest do
  use ExUnit.Case, async: true

  alias Wordle.Emoji

  describe "from_evaluation/0" do
    test "returns the emoji for white/nil evaluations" do
      ?a..?z
      |> Enum.to_list
      |> List.to_string
      |> String.graphemes
      |> Enum.each(fn letter ->
        assert Emoji.from_evaluation({letter, nil}) =~ ~r/:white_#{letter}:\d+/
      end)
    end

    test "returns the emoji for green/correct evaluations" do
      ?a..?z
      |> Enum.to_list
      |> List.to_string
      |> String.graphemes
      |> Enum.each(fn letter ->
        assert Emoji.from_evaluation({letter, :correct}) =~ ~r/:green_#{letter}:\d+/
      end)
    end

    test "returns the emoji for yellow/present evaluations" do
      ?a..?z
      |> Enum.to_list
      |> List.to_string
      |> String.graphemes
      |> Enum.each(fn letter ->
        assert Emoji.from_evaluation({letter, :present}) =~ ~r/:yellow_#{letter}:\d+/
      end)

    end
    test "returns the emoji for gray/absent evaluations" do
      ?a..?z
      |> Enum.to_list
      |> List.to_string
      |> String.graphemes
      |> Enum.each(fn letter ->
        assert Emoji.from_evaluation({letter, :absent}) =~ ~r/:gray_#{letter}:\d+/
      end)
    end
  end

  describe "empty_square/0" do
    test "it returns the empty_square emoji" do
      assert Emoji.empty_square =~ ~r/:empty_square:\d+/
    end
  end
end
