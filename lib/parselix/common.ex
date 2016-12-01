defmodule Parselix.Common do
  use Parselix
  use Parselix.Basic

  @moduledoc """
  Provide parsers which is used commonly.
  """

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc "Parse a whitespace."
  parser :whitespace do
    choice([string("\r\n"), char(" \n\r\t")])
  end
  @doc "Parse whitespaces."
  parser :whitespaces, do: many_1(whitespace)

  @doc "Parse a uppercase character."
  parser :uppercase do
    char("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  end
  @doc "Parse uppercase characters."
  parser :uppercases, do: many_1(uppercase)

  @doc "Parse a lowercase character."
  parser :lowercase do
    char("abcdefghijklmnopqrstuvwxyz")
  end
  @doc "Parse lowercase characters."
  parser :lowercases, do: many_1(lowercase)

  @doc "Parse a letter."
  parser :letter do
    char("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
  end
  @doc "Parse letters."
  parser :letters, do: many_1(letter)

  @doc "Parse a digit."
  parser :digit do
    char("0123456789")
  end
  @doc "Parse digits."
  parser :digits, do: many_1(digit)

  @doc "Parse a hex digit."
  parser :hex_digit do
    char("0123456789abcdefABCDEF")
  end
  @doc "Parse hex digits."
  parser :hex_digits, do: many_1(hex_digit)

  @doc "Parse a octo digit."
  parser :oct_digit do
    char("01234567")
  end
  @doc "Parse octo digits."
  parser :oct_digits, do: many_1(oct_digit)

end
