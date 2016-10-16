defmodule CommonTest do
  use ExUnit.Case
  use Parselix
  use Parselix.Basic
  use Parselix.Common

  test "whitespace" do
    assert many(whitespace).(" \t\n\r \r\n a  ", position)
    == {:ok, [" ", "\t", "\n", "\r", " ", "\r\n", " "], "a  ", position(7, 3, 1)}
    assert whitespaces.(" \t\n\r \r\n a  ", position)
    == {:ok, [" ", "\t", "\n", "\r", " ", "\r\n", " "], "a  ", position(7, 3, 1)}
  end

  test "uppercase" do
    assert uppercases().("ABCabc", position)
    == {:ok, ["A", "B", "C"], "abc", position(3, 0, 3)}
  end

  test "lowercase" do
    assert lowercases().("abcABC", position)
    == {:ok, ["a", "b", "c"], "ABC", position(3, 0, 3)}
  end

  test "letter" do
    assert letters().("ABCabc ", position)
    == {:ok, ["A", "B", "C", "a", "b", "c"], " ", position(6, 0, 6)}
  end

  test "digits" do
    assert digits().("123a", position)
    == {:ok, ["1", "2", "3"], "a", position(3, 0, 3)}
  end

  test "hex_digits" do
    assert hex_digits().("123a ", position)
    == {:ok, ["1", "2", "3", "a"], " ", position(4, 0, 4)}
  end

  test "oct_digits" do
    assert oct_digits().("1738", position)
    == {:ok, ["1", "7", "3"], "8", position(3, 0, 3)}
  end

end
