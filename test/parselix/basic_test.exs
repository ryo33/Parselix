defmodule BasicTest do
  use ExUnit.Case
  use Parselix

  test "token" do
    {result, %AST{label: label, position: position, tree: tree}, remainder, %Position{index: index, vertical: vertical, horizontal: horizontal}} = (parser_token("abc")).("abcdef", %Position{})
    assert result == :ok
    assert label == "token"
    assert tree == "abc"
    assert position == %Position{}
    assert remainder == "def"
    assert index == 3
    assert vertical == 0
    assert horizontal == 3
  end

  test "choice" do
    assert {:ok, %AST{label: "choice", position: %Position{}, tree: %AST{label: "token", position: %Position{}, tree: "abc"}}, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    == (parser_choice([parser_token("abcdefg"), parser_token("bcd"), parser_token("abc")])).("abcdef", %Position{})
  end

end
