defmodule BasicTest do
  use ExUnit.Case
  use Parselix
  import Parselix.Basic

  test "token" do
    assert parser_token("abc").("abcdef", %Position{})
    == {:ok, %AST{label: "token", position: %Position{}, children: "abc"}, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
  end

  test "choice" do
    assert (combinator_choice([parser_token("abcdefg"), parser_token("bcd"), parser_token("abc")])).("abcdef", %Position{})
    == {:ok, %AST{label: "token", position: %Position{}, children: "abc"}, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
  end

  test "option" do
    assert combinator_option(parser_token("abc")).("abcdef", %Position{})
    == {:ok, %AST{label: "token", children: "abc", position: %Position{}}, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert combinator_option(parser_token("bc")).("abcdef", %Position{index: 100})
    == {:ok, :empty, "abcdef", %Position{index: 100}}
  end

  test "sequence" do
    assert combinator_sequence([parser_token("abc"), parser_token("def"), parser_token("ghi")]).("abcdefghijkl", %Position{})
    == {:ok,
        [
          %AST{label: "token", children: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %AST{label: "token", children: "def", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %AST{label: "token", children: "ghi", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "jkl", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert combinator_sequence([parser_token("abc"), parser_token("ddf"), parser_token("ghi")]).("abcdefghijkl", %Position{})
    == {:error, "[parser_token] There is not token.", %Parselix.Position{horizontal: 3, index: 3, vertical: 0}}
  end

  test "many" do
    assert combinator_many(parser_token("abc")).("abcabcabcdef", %Position{})
    == {:ok,
        [
          %AST{label: "token", children: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %AST{label: "token", children: "abc", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %AST{label: "token", children: "abc", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "def", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert combinator_many(parser_token("abc")).("aabcabcabcdef", %Position{})
    == {:ok, [], "aabcabcabcdef", %Position{index: 0, vertical: 0, horizontal: 0}}
  end

  test "dump" do
    assert combinator_dump(parser_token("abc")).("abcdef", %Position{})
    == {:ok, :empty, "def", position(3, 0, 3)}
    assert combinator_dump(parser_token("aac")).("abcdef", %Position{})
    == {:error, "[parser_token] There is not token.", position(0, 0, 0)}
  end

  test "ignore" do
    assert combinator_ignore(parser_token("abc")).("abcdef", %Position{})
    == {:ok, :empty, "def", position(3, 0, 3)}
    assert combinator_ignore(parser_token("aac")).("abcdef", %Position{})
    == {:ok, :empty, "abcdef", position(0, 0, 0)}
  end

end
