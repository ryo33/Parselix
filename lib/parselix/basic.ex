defmodule Parselix.Basic do
  use Parselix

  defmacro __using__(_opts) do
    quote do
      import Basic
    end
  end

  parser "regex" do
    fn _, regex, target, _ ->
      case (Regex.run regex, target, return: :index) |> Enum.find fn {x, _} -> x == 0 end do
        {0, len} -> {:ok, String.slice(target, 0, len), len}
        _ -> {:error, "The regex does not match."}
      end
    end
  end

  parser "string" do
    fn _, option, target, _ ->
      if String.starts_with?(target, option), do: {:ok, option, String.length option}, else: {:error, "There is not string."}
    end
  end

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

  parser "not_char" do
    fn _, option, target, position ->
     case char(option).(target, position) do
        {:ok, _, _, _} -> {:error, "\"#{String.first target}\" appeared.", position}
        _ -> any().(target, position)
      end
    end
  end

  parser "any" do
    fn
      _, _, "", position -> {:error, "EOF appeared.", position}
      _, _, x, _ -> {:ok, String.first(x), String.slice(x, 1, String.length(x) - 1)}
    end
  end

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

  parser "option" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, _, _, _} = x -> x
        _ -> {:ok, :empty, target, position}
      end
    end
  end

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

  parser "map" do
    fn _, {parser, func}, target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} -> {:ok, func.(result), remainder, position}
        x -> x
      end
    end
  end

  parser "clean" do
    fn _, option, target, position ->
      map({option, fn x -> Enum.filter x, fn x -> x != :empty end end}).(target, position)
    end
  end

  parser "flat" do
    fn _, option, target, position ->
      (flat = fn children, flat ->
        case children do
          [head | tail] -> flat.(head, flat) ++ flat.(tail, flat)
          %Parsed{content: children} -> flat.(children, flat)
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

  parser "compress" do
    fn _, option, target, position ->
      map({flat(option), fn x -> (Enum.filter x, fn x -> x !== :empty end) |> Enum.join end}).(target, position)
    end
  end

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

  parser "wrap" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, x, remainder, position} -> {:ok, [x], remainder, position}
        x -> x
      end
    end
  end

  parser "unwrap" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, [x], remainder, position} -> {:ok, x, remainder, position}
        x -> x
      end
    end
  end

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

  parser "pick" do
    fn _, {parser, index}, target, position ->
      case parser.(target, position) do
        {:ok, x, remainder, position} -> {:ok, Enum.at(x, index), remainder, position}
        x -> x
      end
    end
  end

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

  parser "sequence_c" do
    fn _, option, target, position ->
      concat(sequence(option)).(target, position)
    end
  end

  parser "many_c" do
    fn _, option, target, position ->
      concat(many(option)).(target, position)
    end
  end

  parser "many_1" do
    fn _, option, target, position ->
      sequence_c([wrap(option), many(option)]).(target, position)
    end
  end

  parser "many_1_c" do
    fn _, option, target, position ->
      concat(sequence_c([wrap(option), many(option)])).(target, position)
    end
  end

  parser "dump" do
    fn _, option, target, position ->
      case option.(target, position) do
        {:ok, _, remainder, position} -> {:ok, :empty, remainder, position}
        x -> x
      end
    end
  end

  parser "ignore" do
    fn _, option, target, position ->
      dump(option(option)).(target, position)
    end
  end

  parser "check" do
    fn _, {parser, func}, target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} ->
          if func.(result) === true, do: {:ok, result, remainder, position}, else: {:error, "#{inspect result} is a bad result."}
        x -> x
      end
    end
  end

  parser "eof" do
    fn
      _, _, "", position ->
        {:ok, :empty, "", position}
      _, _, _, _ -> {:error, "There is not EOF."}
    end
  end

end
