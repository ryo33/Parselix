defmodule ParselTest do
  use ExUnit.Case
  use Parselix

  test "get_position" do
    assert get_position(%Position{index: 3, vertical: 2, horizontal: 300}, "a\nbc\rdef\r\nghig", "g")
    == %Position{index: 15, vertical: 5, horizontal: 3}
    assert get_position(%Position{index: 3, vertical: 2, horizontal: 3}, "a\nbc\rdef\r\nghig", "g")
    == %Position{index: 15, vertical: 5, horizontal: 3}
  end

  parser "test_parser1" do
    fn _, _, _, _ ->
      {:ok, "abc", "def", position(9, 1, 5)}
    end
  end

  parser "test_parser2" do
    fn _, _, _, _ ->
      {:ok, "abc", 3}
    end
  end

  parser "test_parser3" do
    fn _, _, _, _ ->
      {:ok, "abc", "def"}
    end
  end

  parser "test_parser4" do
    fn a, count, target, position ->
      if count == 10, do: {:ok, "", ""}, else: a.(count + 1).(target, position)
    end
  end

  test "parser" do
    assert test_parser1(nil).("abcdef", position(6, 1, 2))
    == {:ok, "abc", "def", position(9, 1, 5)}
    assert test_parser2(nil).("abcdef", position(6, 1, 2))
    == {:ok, "abc", "def", position(9, 1, 5)}
    assert test_parser3(nil).("abcdef", position(6, 1, 2))
    == {:ok, "abc", "def", position(9, 1, 5)}
    assert test_parser1_l(nil).("abcdef", position(6, 1, 2))
    == {:ok, %Parsed{label: "test_parser1", content: "abc", position: position(6, 1, 2)}, "def", position(9, 1, 5)}
    assert test_parser2_l(nil).("abcdef", position(6, 1, 2))
    == {:ok, %Parsed{label: "test_parser2", content: "abc", position: position(6, 1, 2)}, "def", position(9, 1, 5)}
    assert test_parser3_l(nil).("abcdef", position(6, 1, 2))
    == {:ok, %Parsed{label: "test_parser3", content: "abc", position: position(6, 1, 2)}, "def", position(9, 1, 5)}
    assert test_parser4(0).("", position)
    == {:ok, "", "", position}
  end

end
