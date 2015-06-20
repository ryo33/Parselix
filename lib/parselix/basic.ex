defmodule Parselix.Basic do
  use Parselix

  parser "string" do
    fn option, target, _ ->
      if String.starts_with?(target, option), do: {:ok, option, String.slice(target, Range.new(String.length(option), -1))}, else: {:error, "There is not string."}
    end
  end

  parser "char" do
    fn option, target, position -> choice(String.codepoints(option) |> Enum.map fn x -> string(x) end).(target, position) end
  end

  parser "not_char" do
    fn option, target, position ->
     case char(option).(target, position) do
        {:ok, _, _, _} -> {:error, "\"#{String.first target}\" appeared.", position}
        _ -> any().(target, position)
      end
    end
  end

  parser "any" do
    fn
      _, "", position -> {:error, "EOF appeared.", position}
      _, x, _ -> {:ok, String.first(x), String.slice(x, 1, String.length(x) - 1)}
    end
  end

  parser "choice" do
    fn option, target, position ->
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
    fn option, target, position ->
      case option.(target, position) do
        {:ok, _, _, _} = x -> x
        _ -> {:ok, :empty, target, position}
      end
    end
  end

  parser "sequence" do
    fn option, target, position ->
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
    fn option, target, position ->
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
          ({result, count} = many.(parser, target, position, many)
          result)
      end)
    end
  end

  parser "times" do
    fn option, target, current_position ->
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
    fn {parser, func}, target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} -> {:ok, func.(result), remainder, position}
        x -> x
      end
    end
  end

  parser "flat" do
    fn option, target, position ->
      (flat = fn children, flat ->
        case children do
          [head | tail] -> flat.(head, flat) ++ flat.(tail, flat)
          %AST{children: children} -> flat.(children, flat)
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

  parser "concat" do
    fn option, target, position ->
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
    fn option, target, position ->
      case option.(target, position) do
        {:ok, x, remainder, position} -> {:ok, [x], remainder, position}
        x -> x
      end
    end
  end

  parser "sequence_c" do
    fn option, target, position ->
      concat(sequence(option)).(target, position)
    end
  end

  parser "many_c" do
    fn option, target, position ->
      concat(many(option)).(target, position)
    end
  end

  parser "many_1" do
    fn option, target, position ->
      sequence_c([wrap(option), many(option)]).(target, position)
    end
  end

  parser "many_1_c" do
    fn option, target, position ->
      concat(sequence_c([wrap(option), many(option)])).(target, position)
    end
  end

  parser "dump" do
    fn option, target, position ->
      case option.(target, position) do
        {:ok, _, remainder, position} -> {:ok, :empty, remainder, position}
        x -> x
      end
    end
  end

  parser "ignore" do
    fn option, target, position ->
      dump(option(option)).(target, position)
    end
  end

  parser "check" do
    fn {parser, func}, target, position ->
      case parser.(target, position) do
        {:ok, result, remainder, position} ->
          if func.(result) === true, do: {:ok, result, remainder, position}, else: {:error, "#{inspect result} is a bad result."}
        x -> x
      end
    end
  end

  parser "eof" do
    fn
      _, "", position ->
        {:ok, :empty, "", position}
      _, _, _ -> {:error, "There is not EOF."}
    end
  end

end
