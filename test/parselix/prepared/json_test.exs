defmodule JSONTest do
  use ExUnit.Case
  use Parselix
  use Basic
  use Common
  use Prepared
  use JSON

  test "other" do
    assert {any, string("["), string("]")} |> between |> parse("[a]", position)
    == {:ok, "a", "", position(3, 0, 3)}
    assert any |> token |> parse(" a", position)
    == {:ok, "a", "", position(2, 0, 2)}
    assert {string("a"), string("b")} |> separate |> parse("ababab", position)
    == {:ok, ["a", "a", "a"], "b", position(5, 0, 5)}
  end

  test "literal" do
    assert json_string.("\"string!\"", position)
    == {:ok, "string!", "", position(9, 0, 9)}
    assert json_number.("1e3", position)
    == {:ok, 1000, "", position(3, 0, 3)}
    assert json_number.("-1", position)
    == {:ok, -1, "", position(2, 0, 2)}
    assert json_number.("1.03e3", position)
    == {:ok, 1.03e3, "", position(6, 0, 6)}
    assert json_number.("-1.03e-3", position)
    == {:ok, -1.03e-3, "", position(8, 0, 8)}
  end

  test "array" do
    assert json.("[3.5, 2]", position)
    == {:ok, [3.5, 2], "", position(8, 0, 8)}
  end

  test "object" do
    assert object.("{\"value\": 3.5}", position)
    == {:ok, %{"value" => 3.5}, "", position(14, 0, 14)}
    assert object.("{\"value\": 3.5, \"child\": {}}", position)
    == {:ok, %{"child" => %{}, "value" => 3.5}, "", position(27, 0, 27)}
  end

  test "value" do
    assert value |> parse("true")
    == {:ok, true, "", position(4, 0, 4)}
    assert value |> parse("false")
    == {:ok, false, "", position(5, 0, 5)}
    assert value |> parse("null")
    == {:ok, nil, "", position(4, 0, 4)}
    assert value |> parse("3")
    == {:ok, 3, "", position(1, 0, 1)}
    assert value |> parse("3.5")
    == {:ok, 3.5, "", position(3, 0, 3)}
    assert value.("{\"value\": 3.5}", position)
    == {:ok, %{"value" => 3.5}, "", position(14, 0, 14)}
    assert value.("[3.5, 2]", position)
    == {:ok, [3.5, 2], "", position(8, 0, 8)}
    assert value |> parse("\"abc\"")
    == {:ok, "abc", "", position(5, 0, 5)}
  end

  test "json" do
    assert json |> parse("""
{
  "Image": {
    "Width":  800,
    "Height": 600,
    "Title":  "View from 15th Floor",
    "Thumbnail": {
      "Url":    "http://www.example.com/image/481989943",
      "Height": 125,
      "Width":  100
    },
    "Animated" : false,
    "IDs": [116, 943, 234, 38793]
  }
}
    """)
    == {:ok,
      %{"Image" => %{
          "Width" => 800,
          "Height" => 600,
          "Title" => "View from 15th Floor",
          "Thumbnail" => %{
            "Url" => "http://www.example.com/image/481989943",
            "Height" => 125,
            "Width" => 100
          },
          "Animated" => false,
          "IDs" => [116, 943, 234, 38793]
        }
      }, "", position(236, 14, 0)}
  end

end
