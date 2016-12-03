defmodule BasicTest do
  use ExUnit.Case
  use Parselix
  use Parselix.Basic

  def string2(str) do
    str
    |> String.graphemes()
    |> Enum.map(fn char -> string(char) end)
    |> sequence
    |> concat
  end

  test "error_message" do
    assert error_message(string2("abc"), "error").("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert error_message(string2("abx"), "error").("abcdef", %Position{})
    == {:error, "error", %Position{}}
  end

  test "meta" do
    result = %Meta{label: nil, value: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}}
    assert meta(string("abc")).("abcdef", %Position{})
    == {:ok, result, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    result = %Meta{label: "string", value: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}}
    assert meta(string("abc"), "string").("abcdef", %Position{})
    == {:ok, result, "def", %Position{index: 3, vertical: 0, horizontal: 3}}
  end

  test "regex" do
    assert regex(~r/ab*c/).("abbcdef", position)
    == {:ok, "abbc", "def", position(4, 0, 4)}
    assert regex(~r/ab*c/).("defabbc", position)
    == {:error, "The regex does not match.", position}
  end

  test "string" do
    assert string("abc").("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert string("abx").("abcdef", %Position{})
    == {:error, "There is not the string.", %Position{}}
  end

  test "char" do
    assert many(char("abc")).("abccbad", position())
    == {:ok, ["a", "b", "c", "c", "b", "a"], "d", position(6, 0, 6)}
    assert char("abc").("d", position())
    == {:error, "There is not an expected character.", position}
    assert char("abc").("", position())
    == {:error, "EOF appeared.", position}
  end

  test "not_char" do
    assert not_char("abc").("abc", position)
    == {:error, "\"a\" appeared.", position(0, 0, 0)}
    assert many(not_char("def")).("abcd", position)
    == {:ok, ["a", "b", "c"], "d", position(3, 0, 3)}
    assert not_char("abc").("", position)
    == {:error, "EOF appeared.", position}
  end

  test "any" do
    assert many(any()).("abc", position)
    == {:ok, ["a", "b", "c"], "", position(3, 0, 3)}
    assert any().("", position)
    == {:error, "EOF appeared.", position}
  end

  test "choice" do
    assert (choice([string("abcdefg"), string("bcd"), string("abc")])).("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert (choice([string2("abx"), string2("abcdx"), string2("abcx")])).("abcdef", %Position{})
    == {:error, "There is not the string.", %Position{index: 4, vertical: 0, horizontal: 4}}
  end

  test "option" do
    assert option(string("abc")).("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert option(string("bc")).("abcdef", %Position{index: 100})
    == {:ok, :empty, "abcdef", %Position{index: 100}}
  end

  test "default" do
    assert default(string("abc"), "default").("abcdef", %Position{})
    == {:ok, "abc", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert default(string("bc"), "default").("abcdef", %Position{index: 100})
    == {:ok, "default", "abcdef", %Position{index: 100}}
  end

  test "replace" do
    assert replace(string("abc"), "replacement").("abcdef", %Position{})
    == {:ok, "replacement", "def", %Position{index: 3, vertical: 0, horizontal: 3}}
    assert replace(string("bc"), "replacement").("abcdef", %Position{index: 100})
    == {:error, "There is not the string.", position(100, 0, 0)}
  end

  test "sequence" do
    assert sequence([meta(string("abc")), meta(string("def")), meta(string("ghi"))]).("abcdefghijkl", %Position{})
    == {:ok,
        [
          %Meta{label: nil, value: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %Meta{label: nil, value: "def", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %Meta{label: nil, value: "ghi", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "jkl", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert sequence([string("abc"), string("ddf"), string("ghi")]).("abcdefghijkl", %Position{})
    == {:error, "There is not the string.", %Parselix.Position{horizontal: 3, index: 3, vertical: 0}}
  end

  test "many" do
    assert many(meta(string("abc"))).("abcabcabcdef", %Position{})
    == {:ok,
        [
          %Meta{label: nil, value: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %Meta{label: nil, value: "abc", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %Meta{label: nil, value: "abc", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "def", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert many(string("abc")).("aabcabcabcdef", position)
    == {:ok, [], "aabcabcabcdef", %Position{index: 0, vertical: 0, horizontal: 0}}
    assert many(string("abc"), 3..5).("abcabc", position)
    == {:error, "The count is out of the range.", position}
    assert many(string("abc"), 3..5).("abcabcabc", position)
    == {:ok, ["abc", "abc", "abc"], "", position(9, 0, 9)}
    assert many(string("abc"), 3..5).("abcabcabcabc", position)
    == {:ok, ["abc", "abc", "abc", "abc"], "", position(12, 0, 12)}
    assert many(string("abc"), 3..5).("abcabcabcabcabc", position)
    == {:ok, ["abc", "abc", "abc", "abc", "abc"], "", position(15, 0, 15)}
    assert many(string("abc"), 3..5).("abcabcabcabcabcabc", position)
    == {:ok, ["abc", "abc", "abc", "abc", "abc"], "abc", position(15, 0, 15)}
    assert many(string("abc"), 2).("abc", position)
    == {:error, "The count is out of the range.", position}
    assert many(string("abc"), 2).("abcabc", position)
    == {:ok, ["abc", "abc"], "", position(6, 0, 6)}
    assert many(string("abc"), 2).("abcabcabc", position)
    == {:ok, ["abc", "abc", "abc"], "", position(9, 0, 9)}
  end

  test "times" do
    assert times(string("abc"), 3).("abcabc", position)
    == {:error, "There is not the string.", %Parselix.Position{vertical: 0, horizontal: 6, index: 6}}
    assert times(string("abc"), 3).("abcabcabc", position)
    == {:ok, ["abc", "abc", "abc"], "", position(9, 0, 9)}
    assert times(string("abc"), 3).("abcabcabcabc", position)
    == {:ok, ["abc", "abc", "abc"], "abc", position(9, 0, 9)}
  end

  test "map" do
    assert map(string("123"), fn x -> String.to_integer x end).("123456", position())
    == {:ok, 123, "456", position(3, 0, 3)}
  end

  test "clean" do
    assert [dump(many(string("a"))), string("b"), string("c")] |> sequence |> clean |> parse("aaabcd", position)
    == {:ok, ["b", "c"], "d", position(5, 0, 5)}
  end

  test "flat" do
    assert flat(sequence([string("a"), sequence([string("b"), sequence([string("c"), string("d")])]), sequence([string("e")])])).("abcde", %Position{})
    == {:ok, ["a", "b", "c", "d", "e"], "", position(5, 0, 5)}
  end

  test "flat_once" do
    assert flat_once(sequence([string("a"), sequence([string("b"), sequence([string("c"), string("d")])]), sequence([string("e")])])).("abcde", %Position{})
    == {:ok, ["a", "b", ["c", "d"], "e"], "", position(5, 0, 5)}
  end

  test "concat" do
    assert concat(sequence([string("a"), sequence([string("b"), sequence([string("c"), string("d")])]), sequence([string("e")])])).("abcde", %Position{})
    == {:ok, "abcde", "", position(5, 0, 5)}
  end

  test "wrap" do
    assert wrap(string("a")).("abc", position(0, 0, 0))
    == {:ok, ["a"], "bc", position(1, 0, 1)}
  end

  test "unwrap" do
    assert unwrap(wrap(string("a"))).("abc", position(0, 0, 0))
    == {:ok, "a", "bc", position(1, 0, 1)}
  end

  test "unwrap_r" do
    assert unwrap_r(wrap(wrap(wrap(wrap(string("a")))))).("abc", position(0, 0, 0))
    == {:ok, "a", "bc", position(1, 0, 1)}
  end

  test "pick" do
    assert many(any) |> pick(1) |> parse("abc", position)
    == {:ok, "b", "", position(3, 0, 3)}
  end

  test "slice" do
    assert many(any) |> slice(2..4) |> parse("abcdefghij", position)
    == {:ok, ["c", "d", "e"], "", position(10, 0, 10)}
  end

  test "many_1" do
    assert many_1(meta(string("abc"))).("abcabcabcdef", %Position{})
    == {:ok,
        [
          %Meta{label: nil, value: "abc", position: %Position{index: 0, vertical: 0, horizontal: 0}},
          %Meta{label: nil, value: "abc", position: %Position{index: 3, vertical: 0, horizontal: 3}},
          %Meta{label: nil, value: "abc", position: %Position{index: 6, vertical: 0, horizontal: 6}}
        ], "def", %Position{index: 9, vertical: 0, horizontal: 9}}
    assert many_1(string("abc")).("aabcabcabcdef", %Position{})
    == {:error, "The count is out of the range.", %Position{index: 0, vertical: 0, horizontal: 0}}
  end

  test "dump" do
    assert dump(string("abc")).("abcdef", %Position{})
    == {:ok, :empty, "def", position(3, 0, 3)}
    assert dump(string("aac")).("abcdef", %Position{})
    == {:error, "There is not the string.", position(0, 0, 0)}
  end

  test "ignore" do
    assert ignore(string("abc")).("abcdef", %Position{})
    == {:ok, :empty, "abcdef", position(0, 0, 0)}
    assert ignore(string("aac")).("abcdef", %Position{})
    == {:error, "There is not the string.", position(0, 0, 0)}
  end

  test "check" do
    assert check(string("abc"), fn x -> if x === "abc", do: true end).("abcdef", position)
    == {:ok, "abc", "def", position(3, 0, 3)}
    assert check(string("abc"), fn x -> if x === "xxx", do: true end).("abcdef", position)
    == {:error, "\"abc\" is a bad result.", position}
  end

  test "eof" do
    assert eof().("abc", position)
    == {:error, "There is not EOF.", position}
    assert eof().("", position)
    == {:ok, :eof, "", position}
    assert sequence([string("abc"), eof()]).("abc", position)
    == {:ok, ["abc", :eof], "", position(3, 0, 3)}
  end

end
