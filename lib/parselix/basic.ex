defmodule Parselix.Basic do
  use Parselix

  @moduledoc """
  Provide basic parsers.
  """

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc "Replaces error messages."
  def error_message(parser, message) do
    fn target, position ->
      case parser.(target, position) do
        {:error, _, _} -> {:error, message, position}
        x -> x
      end
    end
  end

  @doc "Attaches a meta data to the result of the given parser."
  def meta(parser), do: meta(parser, nil)
  parser :meta, [parser, label] do
    fn target, position ->
      mapper = fn result ->
        %Meta{label: label, value: result, position: position}
      end
      map(parser, mapper).(target, position)
    end
  end

  @doc "Parses a string which matches against the given regex."
  parser :regex, [regex] do
    fn target, position ->
      case (Regex.run regex, target, return: :index) |> Enum.find(fn {x, _} -> x == 0 end) do
        {0, len} -> {:ok, String.slice(target, 0, len), len}
        _ -> {:error, "The regex does not match."}
      end
      |> format_result("regex", target, position)
    end
  end

  @doc "Parses a specified string."
  parser :string, [option] do
    fn target, position ->
      if String.starts_with?(target, option) do
        {:ok, option, String.length option}
      else
        {:error, "There is not the string."}
      end
      |> format_result("string", target, position)
    end
  end

  @doc "Parses a specified character."
  parser :char, [option] do
    fn target, position ->
      case any.(target, position) do
        {:ok, char, remainder, position} ->
          if String.contains? option, char do
            {:ok, char, remainder, position}
          else
            {:error, "There is not an expected character."}
          end
        x -> x
      end
      |> format_result("char", target, position)
    end
  end

  @doc "Parses a not specified character."
  parser :not_char, [option] do
    fn target, position ->
      case char(option).(target, position) do
        {:ok, _, _, _} -> {:error, "\"#{String.first target}\" appeared.", position}
        _ -> any().(target, position)
      end
      |> format_result("not_char", target, position)
    end
  end

  @doc "Parses any character."
  parser :any do
    fn target, position ->
      case target do
        "" -> {:error, "EOF appeared.", position}
        x -> {:ok, String.first(x), 1}
      end
      |> format_result("any", target, position)
    end
  end

  @doc "Returns a result of the given parser which succeeds first."
  def choice([]) do
    fn _, position ->
      {:error, "No parser succeeded", position}
    end
  end
  def choice([parser | tail]) do
    fn target, position ->
      case parser.(target, position) do
        {:ok, _, _, _} = result -> result
        {:error, _, pos1} = error1 ->
          case choice(tail).(target, position) do
            {:ok, _, _, _} = result -> result
            {:error, _, pos2} = error2 -> if pos1.index < pos2.index do
              error2
            else
              error1
            end
          end
      end
      |> format_result("choice", target, position)
    end
  end

  @doc "Parses 0 times or once."
  parser :option, [option] do
    fn target, position ->
      case option.(target, position) do
        {:ok, _, _, _} = x -> x
        _ -> {:ok, :empty, target, position}
      end
    end
  end

  @doc "Returns a default value when parser failed."
  parser :default, [parser, default] do
    parser |> option |> map(fn x -> if x == :empty, do: default, else: x end)
  end

  @doc "Replaces the result of the given parser."
  parser :replace, [parser, replacement] do
    parser |> map(fn _ -> replacement end)
  end

  @doc "Parses in sequence."
  def sequence([]), do: fn target, position -> {:ok, [], target, position} end
  def sequence([parser | tail]) do
    fn target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} ->
          sequence(tail)
          |> map(fn tail_result ->
            [result | tail_result]
          end)
          |> parse(remainder, position)
        x -> x
      end
    end
  end

  @doc "Parses 0 or more times."
  def many(parser, min..max), do: many(parser, min, max)
  def many(parser, min \\ 0, max \\ -1) do
    fn target, position ->
      if max == 0 do
        {:ok, [], target, position}
      else
        case parser.(target, position) do
          {:ok, result, remainder, position} ->
            many(parser, min - 1, max - 1)
            |> map(fn tail_result ->
              [result | tail_result]
            end)
            |> parse(remainder, position)
          {:error, _, _} ->
            if min <= 0 do
              {:ok, [], target, position}
            else
              {:error, "The count is out of the range.", position}
            end
        end
        |> case do
          {:error, message, _} -> {:error, message, position}
          x -> x
        end
      end
    end
  end

  @doc "Parses X times."
  def times(_parser, time) when time <= 0, do: fn target, position -> {:ok, [], target, position} end
  def times(parser, time) do
    fn target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} ->
          times(parser, time - 1)
          |> map(fn tail_result ->
            [result | tail_result]
          end)
          |> parse(remainder, position)
        x -> x
      end
    end
  end

  @doc "Maps the result of the given parser."
  def map(parser, func) do
    fn target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} -> {:ok, func.(result), remainder, position}
        x -> x
      end
    end
  end

  @doc "Removes :empty from the result of the given parser."
  parser :clean, [parser] do
    parser |> map(fn x -> Enum.filter x, fn x -> x != :empty end end)
  end

  @doc "Flattens the result of the given parser."
  parser :flat, [parser] do
    func = fn x, func ->
      case x do
        list when is_list(list) -> flatten(list, &func.(&1, func))
        x -> x
      end
    end
    parser |> map(&flatten(&1, fn x -> func.(x, func) end))
  end

  @doc "Flattens the result of the given parser once."
  parser :flat_once, [parser] do
    parser |> map(&flatten/1)
  end

  defp flatten(_list, _mapper \\ fn x -> x end)
  defp flatten([head | tail], mapper) do
    case head do
      head when is_list(head) -> mapper.(head) ++ flatten(tail, mapper)
      head -> [mapper.(head) | flatten(tail, mapper)]
    end
  end
  defp flatten([], _mapper), do: []
  defp flatten(x, _mapper), do: [x]

  @doc "Concatenates the result of the given parser to a string."
  parser :concat, [parser] do
    parser |> flat |> map(fn x -> (Enum.filter x, fn x -> x !== :empty end) |> Enum.join end)
  end

  @doc "Puts the result of the given parser into an empty array."
  parser :wrap, [parser] do
    parser |> map(&([&1]))
  end

  @doc "Puts the value out of the result of the given parser."
  parser :unwrap, [parser] do
    parser |> map(fn [x] -> x end)
  end

  @doc "Recursively puts the value out of the result of the given parser."
  parser :unwrap_r, [parser] do
    unwrap = fn
      [x], unwrap -> unwrap.(x, unwrap)
      x, _ -> x
    end
    parser |> map(&unwrap.(&1, unwrap))
  end

  @doc "Picks one value from the result of the given parser."
  parser :pick, [parser, index] do
    parser |> map(&Enum.at(&1, index))
  end

  @doc "Slices the result of the given parser."
  parser :slice, [parser, range] do
    parser |> map(&Enum.slice(&1, range))
  end
  parser :slice, [parser, start, count] do
    parser |> map(&Enum.slice(&1, start, count))
  end

  @doc "Parses 1 or more times."
  parser :many_1, [option] do
    fn target, position ->
      many(option, 1)
      |> parse(target, position)
    end
  end

  @doc "Dumps the result of the given parser."
  parser :dump, [parser] do
    parser |> map(fn _ -> :empty end)
  end

  @doc "Ignores the result of the given parser."
  def ignore(parser) do
    fn target, position ->
      parser
      |> parse(target, position)
      |> case do
        {:ok, _, _, _} -> {:ok, :empty, target, position}
        x -> x
      end
    end
  end

  @doc "Validates the result of the given parser."
  parser :check, [parser, func] do
    fn target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} ->
          if func.(result) === true, do: {:ok, result, remainder, position}, else: {:error, "#{inspect result} is a bad result."}
        x -> x
      end
      |> format_result("check", target, position)
    end
  end

  @doc "Parses the end of text."
  parser :eof do
    fn
      "", position -> {:ok, :eof, "", position}
      _, position -> {:error, "There is not EOF.", position}
    end
  end
end
