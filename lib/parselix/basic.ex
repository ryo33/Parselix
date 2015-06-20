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
      (many = fn target, position, many ->
        case option.(target, position) do
          {:ok, ast, remainder, position} ->
            case many.(remainder, position, many) do
              {:ok, next_ast, remainder, position} -> {:ok, [ast | next_ast], remainder, position}
              _ -> {:ok, [ast], remainder, position}
            end
          _ -> {:ok, [], target, position}
        end
      end
      many.(target, position, many))
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

end
