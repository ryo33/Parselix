defmodule ParselTest do
  use ExUnit.Case
  use Parselix
  import Parselix.Basic

  test "get_position" do
    assert get_position(%Position{index: 1, vertical: 2, horizontal: 300}, "a\nbc\ndef\nghig", "ef\nghig")
    == %Position{index: 7, vertical: 4, horizontal: 1}
    assert get_position(%Position{index: 1, vertical: 2, horizontal: 3}, "a\nbc\ndef\nghig", "ef\nghig")
    == %Position{index: 7, vertical: 4, horizontal: 1}
  end

  parser "test_parser1" do
    fn _, _, _ ->
      {:ok, "abc", "def", position(9, 1, 5)}
    end
  end

  parser "test_parser2" do
    fn _, _, _ ->
      {:ok, "abc", 3}
    end
  end

  parser "test_parser3" do
    fn _, _, _ ->
      {:ok, "abc", "def"}
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
    == {:ok, %AST{label: "test_parser1", children: "abc", position: position(6, 1, 2)}, "def", position(9, 1, 5)}
    assert test_parser2_l(nil).("abcdef", position(6, 1, 2))
    == {:ok, %AST{label: "test_parser2", children: "abc", position: position(6, 1, 2)}, "def", position(9, 1, 5)}
    assert test_parser3_l(nil).("abcdef", position(6, 1, 2))
    == {:ok, %AST{label: "test_parser3", children: "abc", position: position(6, 1, 2)}, "def", position(9, 1, 5)}
  end

end
