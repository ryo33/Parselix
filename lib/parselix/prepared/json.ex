defmodule Parselix.Prepared.JSON do
  use Parselix
  use Parselix.Basic
  use Parselix.Common

  @moduledoc """
  Provide a json parser.

  ##Example
      json |> parse(JSON)
  """

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  parser :between, [parser, left, right] do
    [dump(left), parser, dump(right)]
    |> sequence
    |> pick(1)
  end

  parser :token, [parser] do
    between(parser, option(whitespaces), option(whitespaces))
  end

  parser :separate, [parser, separator] do
    [parser, sequence([dump(separator), parser]) |> pick(1) |> many]
    |> sequence
    |> flat_once
  end

  parser :json do
    token(value)
  end

  parser :begin_array do
    token(string "[")
  end

  parser :end_array do
    token(string "]")
  end

  parser :begin_object do
    token(string "{")
  end

  parser :end_object do
    token(string "}")
  end

  parser :name_separator do
    token(string ":")
  end

  parser :value_separator do
    token(string ",")
  end

  parser :value do
    [replace(string("false"), false), replace(string("true"), true), replace(string("null"), nil), json_number, json_string, object, array]
    |> choice
  end

  parser :object do
    between(separate(member, value_separator) |> default([]) |> map(fn x -> Enum.into(x, %{}) end), begin_object, end_object)
  end

  parser :member do
    [json_string, name_separator, value]
    |> sequence
    |> map(fn [key, _, value] -> {key, value} end)
  end

  parser :array do
    between(separate(value, value_separator), begin_array, end_array)
    |> unwrap_r
    |> flat_once
    |> clean
  end

  parser :json_number do
    [float, integer]
    |> choice
  end

  parser :integer do
    [option(string("-")), map(int |> concat, fn x -> x <> ".0" end), option(exp)]
    |> sequence
    |> concat
    |> map(fn x -> String.to_float(x) |> round end)
  end

  parser :int do
    [string("0"), [char("123456789"), option(digits)] |> sequence]
    |> choice
  end

  parser :float do
    [option(string("-")), int, frac, option(exp)]
    |> sequence
    |> concat
    |> map(fn x -> String.to_float(x) end)
  end

  parser :exp do
    [char("eE"), option(char("+-")), int]
    |> sequence
  end

  parser :frac do
    [string("."), digits]
    |> sequence
  end

  parser :json_string do
    between(many(json_char), string("\""), string("\""))
    |> concat
  end

  parser :json_char do
    [unescaped, [string("\\"), choice([char("\"\\/bfnrt"), times(hex_digit, 4)])] |> sequence]
    |> choice
  end

  parser :unescaped do
    any
    |> check(fn x ->
      [x] = to_char_list(x)
      if x == 0x20 || x == 0x21 || (x >= 0x23 && x <= 0x5B) || (x >= 0x5D && x <= 0x10FFFF), do: true, else: false
    end)
  end
end
