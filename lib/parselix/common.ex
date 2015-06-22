defmodule Parselix.Common do
  use Parselix
  use Basic

  defmacro __using__(_opts) do
    quote do
      import Common
    end
  end

  parser "whitespace" do
    fn _, _, target, position ->
      choice([string("\r\n"), char(" \n\r\t")]).(target, position)
    end
  end
  parser "whitespaces", do: fn _, _, target, position -> many_1(whitespace).(target, position) end

  parser "uppercase" do
    fn _, _, target, position ->
      char("ABCDEFGHIJKLMNOPQRSTUVWXYZ").(target, position)
    end
  end
  parser "uppercases", do: fn _, _, target, position -> many_1(uppercase).(target, position) end

  parser "lowercase" do
    fn _, _, target, position ->
      char("abcdefghijklmnopqrstuvwxyz").(target, position)
    end
  end
  parser "lowercases", do: fn _, _, target, position -> many_1(lowercase).(target, position) end

  parser "letter" do
    fn _, _, target, position ->
      char("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").(target, position)
    end
  end
  parser "letters", do: fn _, _, target, position -> many_1(letter).(target, position) end

  parser "digit" do
    fn _, _, target, position ->
      char("0123456789").(target, position)
    end
  end
  parser "digits", do: fn _, _, target, position -> many_1(digit).(target, position) end

  parser "hex_digit" do
    fn _, _, target, position ->
      char("0123456789abcdefABCDEF").(target, position)
    end
  end
  parser "hex_digits", do: fn _, _, target, position -> many_1(hex_digit).(target, position) end

  parser "oct_digit" do
    fn _, _, target, position ->
      char("01234567").(target, position)
    end
  end
  parser "oct_digits", do: fn _, _, target, position -> many_1(oct_digit).(target, position) end

end
