defmodule BasicTest do
  use ExUnit.Case
  use Parselix
  import Parselix.Basic

  test "token" do
    assert token("abc").("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
  end

  test "choice" do
    assert (choice([token("abcdefg"), token("bcd"), token("abc")])).("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
  end

  test "option" do
    assert option(token("abc")).("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert option(token("bc")).("abcdef", %Position{index: 100})
    == {:ok, :empty, "abcdef", %Position{index: 100}}
  end

  test "sequence" do
    assert sequence([token_l("abc"), token_l("def"), token_l("ghi")]).("abcdefghijkl", %Position{})
    == {:ok,
        [
          %AST{label: "token", children: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %AST{label: "token", children: "def", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %AST{label: "token", children: "ghi", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "jkl", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert sequence([token("abc"), token("ddf"), token("ghi")]).("abcdefghijkl", %Position{})
    == {:error, "There is not token.", %Parselix.Position{horizontal: 3, index: 3, vertical: 0}}
  end

  test "many" do
    assert many(token_l("abc")).("abcabcabcdef", %Position{})
    == {:ok,
        [
          %AST{label: "token", children: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %AST{label: "token", children: "abc", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %AST{label: "token", children: "abc", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "def", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert many(token("abc")).("aabcabcabcdef", %Position{})
    == {:ok, [], "aabcabcabcdef", %Position{index: 0, vertical: 0, horizontal: 0}}
  end

  test "dump" do
    assert dump(token("abc")).("abcdef", %Position{})
    == {:ok, :empty, "def", position(3, 0, 3)}
    assert dump(token("aac")).("abcdef", %Position{})
    == {:error, "There is not token.", position(0, 0, 0)}
  end

  test "ignore" do
    assert ignore(token("abc")).("abcdef", %Position{})
    == {:ok, :empty, "def", position(3, 0, 3)}
    assert ignore(token("aac")).("abcdef", %Position{})
    == {:ok, :empty, "abcdef", position(0, 0, 0)}
  end

end
