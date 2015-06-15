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

  test "flat" do
    assert flat(sequence([token("a"), sequence([token("b"), sequence([token("c"), token("d")])]), sequence([token("e")])])).("abcde", %Position{})
    == {:ok, ["a", "b", "c", "d", "e"], "", position(5, 0, 5)}
  end

  test "concat" do
    assert concat(sequence([token("a"), sequence([token("b"), sequence([token("c"), token("d")])]), sequence([token("e")])])).("abcde", %Position{})
    == {:ok, ["a", "b", ["c", "d"], "e"], "", position(5, 0, 5)}
    assert sequence_c([ignore(token("abc")), token("def")]).("abcdef", position())
    == {:ok, ["def"], "", position(6, 0, 6)}
  end

  test "wrap" do
    assert wrap(token("a")).("abc", position(0, 0, 0))
    == {:ok, ["a"], "bc", position(1, 0, 1)}
  end

  test "sequence_c" do
    assert sequence_c([token("a"), sequence([token("b"), sequence([token("c"), token("d")])]), sequence([token("e")])]).("abcde", %Position{})
    == {:ok, ["a", "b", ["c", "d"], "e"], "", position(5, 0, 5)}
  end

  test "many_c" do
    assert many_c(sequence([token("a"), sequence([token("b"), token("c")])])).("abcabcabc", %Position{})
    == {:ok, ["a", ["b", "c"], "a", ["b", "c"], "a", ["b", "c"]], "", position(9, 0, 9)}
  end

  test "many_1" do
    assert many_1(token_l("abc")).("abcabcabcdef", %Position{})
    == {:ok,
        [
          %AST{label: "token", children: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %AST{label: "token", children: "abc", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %AST{label: "token", children: "abc", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "def", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert many_1(token("abc")).("aabcabcabcdef", %Position{})
    == {:error, "There is not token.", %Position{index: 0, vertical: 0, horizontal: 0}}
  end

  test "many_1_c" do
    assert many_1_c(sequence([token("a"), sequence([token("b"), token("c")])])).("abcabcabc", %Position{})
    == {:ok, ["a", ["b", "c"], "a", ["b", "c"], "a", ["b", "c"]], "", position(9, 0, 9)}
    assert many_1_c(sequence([token("a"), sequence([token("b"), token("c")])])).("dbcabcabc", %Position{})
    == {:error, "There is not token.", position(0, 0, 0)}
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
