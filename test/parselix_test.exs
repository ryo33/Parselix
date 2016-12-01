defmodule ParselTest do
  use ExUnit.Case
  use Parselix

  parser :test_parser0 do
    fn target, position ->
      {:ok, "abc", "def"}
      |> format_result(target, position)
    end
  end

  parser :test_parser1 do
    fn target, position ->
      {:ok, "abc", "def", position(9, 1, 5)}
      |> format_result(target, position)
    end
  end

  parser :test_parser2 do
    fn target, position ->
      {:ok, "abc", 3}
      |> format_result(target, position)
    end
  end

  parser :test_parser3 do
    fn target, position ->
      {:ok, "abc", "def"}
      |> format_result(target, position)
    end
  end

  test "position" do
    assert position(1, 2, 3)
    == %Position{index: 1, vertical: 2, horizontal: 3}
  end

  test "parse" do
    assert test_parser0 |> parse("abcdef", position(1, 1, 1))
    == {:ok, "abc", "def", position(4, 1, 4)}
    assert test_parser0 |> parse("abcdef")
    == {:ok, "abc", "def", position(3, 0, 3)}
  end

  test "get_position" do
    assert get_position(%Position{index: 3, vertical: 2, horizontal: 300}, "a\nbc\rdef\r\nghig", "g")
    == %Position{index: 15, vertical: 5, horizontal: 3}
    assert get_position(%Position{index: 3, vertical: 2, horizontal: 3}, "a\nbc\rdef\r\nghig", "g")
    == %Position{index: 15, vertical: 5, horizontal: 3}
  end

  def test_parser4(count) do
    fn target, position ->
      if count >= 10 do
        {:ok, "", "", position}
      else
        test_parser4(count + 1).(target, position)
      end
    end
  end

  def test_parser5(count) do
    parser_body do
      if count >= 10 do
        test_parser4(0)
      else
        test_parser5(count + 1)
      end
    end
  end

  test "parser" do
    assert test_parser1.("abcdef", position(6, 1, 2))
    == {:ok, "abc", "def", position(9, 1, 5)}
    assert test_parser2.("abcdef", position(6, 1, 2))
    == {:ok, "abc", "def", position(9, 1, 5)}
    assert test_parser3.("abcdef", position(6, 1, 2))
    == {:ok, "abc", "def", position(9, 1, 5)}
    assert test_parser4(0).("", position)
    == {:ok, "", "", position}
    assert test_parser5(0).("", position)
    == {:ok, "", "", position}
  end

end
