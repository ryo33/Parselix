defmodule ParselTest do
  use ExUnit.Case
  use Parselix

  test "get_position" do
    assert get_position(%Position{index: 1, vertical: 2, horizontal: 300}, "a\nbc\ndef\nghig", "ef\nghig")
    == %Position{index: 7, vertical: 4, horizontal: 1}
    assert get_position(%Position{index: 1, vertical: 2, horizontal: 3}, "a\nbc\ndef\nghig", "ef\nghig")
    == %Position{index: 7, vertical: 4, horizontal: 1}
  end

  test "unfold" do
    assert unfold(%AST{children: %AST{children: "a"}})
    == %AST{children: "a"}
  end

  test "flat" do
    assert flat(%AST{children: %AST{children: [%AST{children: ["a", %AST{children: "b"}]}, %AST{children: "c"}]}})
    == ["a", "b", "c"]
  end

end
