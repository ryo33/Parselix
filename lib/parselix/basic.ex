defmodule Parselix.Basic do
  use Parselix

  @moduledoc """
  Provide basic parsers.
  """

  defmacro __using__(_opts) do
    quote do
      import Basic
    end
  end

  @doc "Parse a string which matches regex."
  parser "regex" do
    fn _, regex, target, _ ->
      case (Regex.run regex, target, return: :index) |> Enum.find fn {x, _} -> x == 0 end do
        {0, len} -> {:ok, String.slice(target, 0, len), len}
        _ -> {:error, "The regex does not match."}
      end
    end
  end

  @doc "Parse a specified string."
  parser "string" do
    fn _, option, target, _ ->
      if String.starts_with?(target, option), do: {:ok, option, String.length option}, else: {:error, "There is not string."}
    end
  end

  @doc "Parse a specified character."
  parser "char" do
    fn _, option, target, position ->
      case any.(target, position) do
        {:ok, char, remainder, position} ->
          if String.contains? option, char do
            {:ok, char, remainder, position}
          else
            {:error, "There is not an expected character."}
          end
        x -> x
      end
    end
  end

  @doc "Parse a not specified character."
  parser "not_char" do
    fn _, option, target, position ->
     case char(option).(target, position) do
        {:ok, _, _, _} -> {:error, "\"#{String.first target}\" appeared.", position}
        _ -> any().(target, position)
      end
    end
  end

  @doc "Parse any character."
  parser "any" do
    fn
      _, _, "", position -> {:error, "EOF appeared.", position}
      _, _, x, _ -> {:ok, String.first(x), 1}
    end
  end

  @doc "Return a result of parser which succeeds first."
  parser "choice" do
    fn _, option, target, position ->
      case (Enum.map(option, fn parser -> parser.(target, position) end)
      |> Enum.find fn
        {:ok, _,  _, _} -> true
        _ -> false end) do
          {:ok, ast, remainder, position} -> {:ok, ast, remainder, position}
          _ -> {:error, "No parser succeeded."}
        end
    end
  end

  @doc "Parse 0 times or once."
  parser "option" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, _, _, _} = x -> x
        _ -> {:ok, :empty, target, position}
      end
    end
  end

  @doc "Return a default value when parser failed."
  parser "default" do
    fn _, {parser, default}, target, position ->
      parser |> option |> (&(map({&1, &2}))).(fn x -> if x == :empty, do: default, else: x end) |> parse(target, position)
    end
  end

  @doc "Replace and Return the result of parser."
  parser "replace" do
    fn _, {parser, replacement}, target, position ->
      parser |> (&(map({&1, &2}))).(fn _ -> replacement end) |> parse(target, position)
    end
  end

  @doc "Parse in sequence."
  parser "sequence" do
    fn _, option, target, position ->
      (seq = fn
        target, position, [head | tail], seq ->
          case head.(target, position) do
            {:ok, ast, remainder, position} ->
              case seq.(remainder, position, tail, seq) do
                {:ok, next_ast, remainder, position} -> {:ok, [ast | next_ast], remainder, position}
                x -> x
              end
            x -> x
          end
        target, position, [], _ -> {:ok, [], target, position}
      end
      seq.(target, position, option, seq))
    end
  end

  @doc "Parse 0 or more times."
  parser "many" do
    fn _, option, target, position ->
      (many = fn option, target, position, many ->
        case option.(target, position) do
          {:ok, ast, remainder, position} ->
            case many.(option, remainder, position, many) do
              {{:ok, next_ast, remainder, position}, count} -> {{:ok, [ast | next_ast], remainder, position}, count + 1}
              _ -> {{:ok, [ast], remainder, position}, 1}
            end
          _ -> {{:ok, [], target, position}, 0}
        end
      end
      case option do
        {parser, min..max} ->
          ({result, count} = many.(parser, target, position, many)
          if count >= min and count <= max, do: result, else: {:error, "The count is out of the range"})
        {parser, min} ->
          ({result, count} = many.(parser, target, position, many)
          if count >= min, do: result, else: {:error, "The count is out of the range"})
        parser ->
          ({result, _} = many.(parser, target, position, many)
          result)
      end)
    end
  end

  @doc "Parse X times."
  parser "times" do
    fn _, option, target, current_position ->
      (times = fn {parser, time}, target, position, times, count ->
        case parser.(target, position) do
          {:ok, ast, remainder, position} ->
            if count + 1 == time do
              {:ok, [ast], remainder, position}
            else
              case times.(option, remainder, position, times, count + 1) do
                {:ok, next_ast, remainder, position} -> {:ok, [ast | next_ast], remainder, position}
                _ -> {:error, "The parser can't parse this #{time} times.", current_position}
              end
            end
          _ -> {:error, "The parser can't parse this #{time} times.", current_position}
        end
      end
      times.(option, target, current_position, times, 0))
    end
  end

  @doc "Map the parser result."
  parser "map" do
    fn _, {parser, func}, target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} -> {:ok, func.(result), remainder, position}
        x -> x
      end
    end
  end

  @doc "Remove :empty from the parser result."
  parser "clean" do
    fn _, option, target, position ->
      map({option, fn x -> Enum.filter x, fn x -> x != :empty end end}).(target, position)
    end
  end

  @doc "Flatten the parser result."
  parser "flat" do
    fn _, option, target, position ->
      (flat = fn children, flat ->
        case children do
          [head | tail] -> flat.(head, flat) ++ flat.(tail, flat)
          %Meta{content: children} -> flat.(children, flat)
          [] -> []
          x -> [x]
        end
      end
      case option.(target, position) do
        {:ok, children, remainder, position} -> {:ok, flat.(children, flat), remainder, position}
        x -> x
      end)
    end
  end

  @doc "Compress the parser result to a string."
  parser "compress" do
    fn _, option, target, position ->
      map({flat(option), fn x -> (Enum.filter x, fn x -> x !== :empty end) |> Enum.join end}).(target, position)
    end
  end

  @doc "Flatten the parser result once."
  parser "concat" do
    fn _, option, target, position ->
      (concat = fn children, concat ->
        case children do
          [head | tail] ->
            case head do
              :empty -> concat.(tail, concat)
              head when is_list(head) -> head ++ concat.(tail, concat)
              head -> [head | concat.(tail, concat)]
            end
          [] -> []
          x -> [x]
        end
      end
      case option.(target, position) do
        {:ok, children, remainder, position} -> {:ok, concat.(children, concat), remainder, position}
        x -> x
      end)
    end
  end

  @doc "Put the parser result into an empty array."
  parser "wrap" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, x, remainder, position} -> {:ok, [x], remainder, position}
        x -> x
      end
    end
  end

  @doc "Put the value out of the parser result."
  parser "unwrap" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, [x], remainder, position} -> {:ok, x, remainder, position}
        x -> x
      end
    end
  end

  @doc "Put the value out of the parser result recursively."
  parser "unwrap_r" do
    fn _, option, target, position ->
      (unwrap = fn
        [x], unwrap -> unwrap.(x, unwrap)
        x, _ -> x
      end
      case option.(target, position) do
        {:ok, x, remainder, position} -> {:ok, unwrap.(x, unwrap), remainder, position}
        x -> x
      end)
    end
  end

  @doc "Pick one value from the parser result."
  parser "pick" do
    fn _, {parser, index}, target, position ->
      case parser.(target, position) do
        {:ok, x, remainder, position} -> {:ok, Enum.at(x, index), remainder, position}
        x -> x
      end
    end
  end

  @doc "Slice the parser result."
  parser "slice" do
    fn _, {parser, f..l}, target, position ->
      case parser.(target, position) do
        {:ok, x, remainder, position} -> {:ok, Enum.slice(x, f..l), remainder, position}
        x -> x
      end
      _, {parser, start, count}, target, position ->
      case parser.(target, position) do
        {:ok, x, remainder, position} -> {:ok, Enum.slice(x, start, count), remainder, position}
        x -> x
      end
    end
  end

  @doc "Optimized implementation of concat(sequence(parser))."
  parser "sequence_c" do
    fn _, option, target, position ->
      concat(sequence(option)).(target, position)
    end
  end

  @doc "Optimized implementation of concat(many(parser))."
  parser "many_c" do
    fn _, option, target, position ->
      concat(many(option)).(target, position)
    end
  end

  @doc "Parse 1 or more times."
  parser "many_1" do
    fn _, option, target, position ->
      sequence_c([wrap(option), many(option)]).(target, position)
    end
  end

  @doc "Optimized implementation of concat(many_1(parser))."
  parser "many_1_c" do
    fn _, option, target, position ->
      concat(sequence_c([wrap(option), many(option)])).(target, position)
    end
  end

  @doc "Dump the parser result."
  parser "dump" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, _, remainder, position} -> {:ok, :empty, remainder, position}
        x -> x
      end
    end
  end

  @doc "Ignore the parser result."
  parser "ignore" do
    fn _, option, target, position ->
      dump(option(option)).(target, position)
    end
  end

  @doc "Validate the parser result."
  parser "check" do
    fn _, {parser, func}, target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} ->
          if func.(result) === true, do: {:ok, result, remainder, position}, else: {:error, "#{inspect result} is a bad result."}
        x -> x
      end
    end
  end

  @doc "Parse the end of text."
  parser "eof" do
    fn
      _, _, "", position ->
        {:ok, :empty, "", position}
      _, _, _, _ -> {:error, "There is not EOF."}
    end
  end

end
