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
  parser "whitespace" do
    fn _, _, target, position ->
      choice([string("\r\n"), char(" \n\r\t")]).(target, position)
    end
  end
  @doc "Parse whitespaces."
  parser "whitespaces", do: fn _, _, target, position -> many_1(whitespace).(target, position) end

  @doc "Parse a uppercase character."
  parser "uppercase" do
    fn _, _, target, position ->
      char("ABCDEFGHIJKLMNOPQRSTUVWXYZ").(target, position)
    end
  end
  @doc "Parse uppercase characters."
  parser "uppercases", do: fn _, _, target, position -> many_1(uppercase).(target, position) end

  @doc "Parse a lowercase character."
  parser "lowercase" do
    fn _, _, target, position ->
      char("abcdefghijklmnopqrstuvwxyz").(target, position)
    end
  end
  @doc "Parse lowercase characters."
  parser "lowercases", do: fn _, _, target, position -> many_1(lowercase).(target, position) end

  @doc "Parse a letter."
  parser "letter" do
    fn _, _, target, position ->
      char("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").(target, position)
    end
  end
  @doc "Parse letters."
  parser "letters", do: fn _, _, target, position -> many_1(letter).(target, position) end

  @doc "Parse a digit."
  parser "digit" do
    fn _, _, target, position ->
      char("0123456789").(target, position)
    end
  end
  @doc "Parse digits."
  parser "digits", do: fn _, _, target, position -> many_1(digit).(target, position) end

  @doc "Parse a hex digit."
  parser "hex_digit" do
    fn _, _, target, position ->
      char("0123456789abcdefABCDEF").(target, position)
    end
  end
  @doc "Parse hex digits."
  parser "hex_digits", do: fn _, _, target, position -> many_1(hex_digit).(target, position) end

  @doc "Parse a octo digit."
  parser "oct_digit" do
    fn _, _, target, position ->
      char("01234567").(target, position)
    end
  end
  @doc "Parse octo digits."
  parser "oct_digits", do: fn _, _, target, position -> many_1(oct_digit).(target, position) end

end
