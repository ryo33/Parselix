defmodule Parselix.Prepared.JSON do
  use Parselix
  use Basic
  use Common
  use Prepared

  @moduledoc """
  Provide a json parser.

  ##Example
      json |> parse(JSON)
  """

  defmacro __using__(_opts) do
    quote do
      import JSON
    end
  end

  parser "between" do
    fn _, {parser, left, right}, target, position ->
      [dump(left), parser, dump(right)]
      |> sequence
      |> (&(pick({&1, &2}))).(1)
      |> parse(target, position)
    end
  end

  parser "token" do
    fn _, parser, target, position ->
      {parser, option(whitespaces), option(whitespaces)}
      |> between
      |> parse(target, position)
    end
  end

  parser "separate" do
    fn _, {parser, separator}, target, position ->
      [parser, sequence([dump(separator), parser]) |> (&(pick({&1, &2}))).(1) |> many]
      |> sequence
      |> concat
      |> parse(target, position)
    end
  end

  parser "json" do
    fn _, _, target, position ->
      token(value)
      |> parse(target, position)
    end
  end

  parser "begin_array" do
    fn _, _, target, position ->
      token(string "[")
      |> parse(target, position)
    end
  end

  parser "end_array" do
    fn _, _, target, position ->
      token(string "]")
      |> parse(target, position)
    end
  end

  parser "begin_object" do
    fn _, _, target, position ->
      token(string "{")
      |> parse(target, position)
    end
  end

  parser "end_object" do
    fn _, _, target, position ->
      token(string "}")
      |> parse(target, position)
    end
  end

  parser "name_separator" do
    fn _, _, target, position ->
      token(string ":")
      |> parse(target, position)
    end
  end

  parser "value_separator" do
    fn _, _, target, position ->
      token(string ",")
      |> parse(target, position)
    end
  end

  parser "value" do
    fn _, _, target, position ->
      [replace({string("false"), false}), replace({string("true"), true}), replace({string("null"), nil}), object, array, json_number, json_string]
      |> choice
      |> parse(target, position)
    end
  end

  parser "object" do
    fn _, _, target, position ->
      {separate({member, value_separator}) |> (&(default({&1, &2}))).([]) |> (&(map({&1, &2}))).(fn x -> Enum.into(x, %{}) end), begin_object, end_object}
      |> between
      |> parse(target, position)
    end
  end

  parser "member" do
    fn _, _, target, position ->
      [json_string, name_separator, value]
      |> sequence
      |> (&(map({&1, &2}))).(fn [key, _, value] -> {key, value} end)
      |> parse(target, position)
    end
  end

  parser "array" do
    fn _, _, target, position ->
      {separate({value, value_separator}), begin_array, end_array}
      |> between
      |> unwrap_r
      |> concat
      |> clean
      |> parse(target, position)
    end
  end

  parser "json_number" do
    fn _, _, target, position ->
      [float, integer]
      |> choice
      |> parse(target, position)
    end
  end

  parser "integer" do
    fn _, _, target, position ->
      [option(string("-")), map({int |> compress, fn x -> x <> ".0" end}), option(exp)]
      |> sequence
      |> compress
      |> (fn a, b -> map({a, b}) end).(fn x -> String.to_float(x) |> round end)
      |> parse(target, position)
    end
  end

  parser "int" do
    fn _, _, target, position ->
      [string("0"), [char("123456789"), option(digits)] |> sequence]
      |> choice
      |> parse(target, position)
    end
  end

  parser "float" do
    fn _, _, target, position ->
      [option(string("-")), int, frac, option(exp)]
      |> sequence
      |> compress
      |> (fn a, b -> map({a, b}) end).(fn x -> String.to_float(x) end)
      |> parse(target, position)
    end
  end

  parser "exp" do
    fn _, _, target, position ->
      [char("eE"), option(char("+-")), int]
      |> sequence
      |> parse(target, position)
    end
  end

  parser "frac" do
    fn _, _, target, position ->
      [string("."), digits]
      |> sequence
      |> parse(target, position)
    end
  end

  parser "json_string" do
    fn _, _, target, position ->
      {many(json_char), string("\""), string("\"")}
      |> between
      |> compress
      |> parse(target, position)
    end
  end

  parser "json_char" do
    fn _, _, target, position ->
      [unescaped, [string("\\"), choice([char("\"\\/bfnrt"), times({hex_digit, 4})])] |> sequence]
      |> choice
      |> parse(target, position)
    end
  end

  parser "unescaped" do
    fn _, _, target, position ->
      any
      |> (fn a, b -> check {a, b} end).(fn x -> (
      [x] = to_char_list(x)
      if x == 0x20 || x == 0x21 || (x >= 0x23 && x <= 0x5B) || (x >= 0x5D && x <= 0x10FFFF), do: true, else: false
      )end)
      |> parse(target, position)
    end
  end
  
end
