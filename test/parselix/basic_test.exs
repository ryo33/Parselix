defmodule BasicTest do
  use ExUnit.Case
  use Parselix

  test "token" do
    assert parser_token("abc").("abcdef", %Position{})
    == {:ok, %AST{label: "token", position: %Position{}, children: "abc"}, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
  end

  test "choice" do
    assert (parser_choice([parser_token("abcdefg"), parser_token("bcd"), parser_token("abc")])).("abcdef", %Position{})
    == {:ok, %AST{label: "choice", position: %Position{}, children:
        %AST{label: "token", position: %Position{}, children: "abc"}}, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
  end

  test "option" do
    assert parser_option(parser_token("abc")).("abcdef", %Position{})
    == {:ok, %AST{label: "option", position: %Position{}, children:
        %AST{label: "token", children: "abc", position: %Position{}}}, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert parser_option(parser_token("bc")).("abcdef", %Position{index: 100})
    == {:ok, %AST{label: "option", position: %Position{index: 100}, children: :empty}, "abcdef", %Position{index: 100}}
  end

  test "sequence" do
    assert parser_sequence([parser_token("abc"), parser_token("def"), parser_token("ghi")]).("abcdefghijkl", %Position{})
    == {:ok, %AST{label: "sequence", position: %Position{}, children:
        [
          %AST{label: "token", children: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %AST{label: "token", children: "def", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %AST{label: "token", children: "ghi", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ]}, "jkl", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert parser_sequence([parser_token("abc"), parser_token("ddf"), parser_token("ghi")]).("abcdefghijkl", %Position{})
    == {:error, "[sequence] [token] There is not token.", %Parselix.Position{horizontal: 3, index: 3, vertical: 0}}
  end

end
