defmodule Parselix.Basic do
  use Parselix

  parser "token" do
    fn target, option, _ ->
      if String.starts_with?(target, option), do: {:ok, option, String.slice(target, Range.new(String.length(option), -1))}, else: {:error, "There is not token."}
    end
  end

  parser "choice" do
    fn target, option, position ->
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
    fn target, option, position ->
      case option.(target, position) do
        {:ok, _, _, _} = x -> x
        _ -> {:ok, :empty, target, position}
      end
    end
  end

  parser "sequence" do
    fn target, option, position ->
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
    fn target, option, position ->
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

  parser "flat" do
    fn target, option, position ->
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
    fn target, option, position ->
      (concat = fn children, concat ->
        case children do
          [head | tail] ->
            case head do
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

  parser "sequence_c" do
    fn target, option, position ->
      concat(sequence(option)).(target, position)
    end
  end

  parser "many_c" do
    fn target, option, position ->
      concat(many(option)).(target, position)
    end
  end

  parser "many_1" do
    fn target, option, position ->
      sequence_c([option, many(option)]).(target, position)
    end
  end

  parser "dump" do
    fn target, option, position ->
      case option.(target, position) do
        {:ok, _, remainder, position} -> {:ok, :empty, remainder, position}
        x -> x
      end
    end
  end

  parser "ignore" do
    fn target, option, position ->
      dump(option(option)).(target, position)
    end
  end

end
