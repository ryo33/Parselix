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

  parser "number" do
    fn _, _, target, position ->
      char("0123456789").(target, position)
    end
  end
  parser "numbers", do: fn _, _, target, position -> many_1(number).(target, position) end

end
