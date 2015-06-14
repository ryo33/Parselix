defmodule Parselix.Basic do
  import Parselix

  parser "token" do
    fn target, option, _ ->
      if String.starts_with?(target, option), do: {:ok, option, String.slice(target, Range.new(String.length(option), -1))}, else: {:error, "There is not token."}
    end
  end

  combinator "choice" do
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

  combinator "option" do
    fn target, option, position ->
      case option.(target, position) do
        {:ok, _, _, _} = x -> x
        _ -> {:ok, :empty, target, position}
      end
    end
  end

  combinator "sequence" do
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

  combinator "many" do
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

  combinator "dump" do
    fn target, option, position ->
      case option.(target, position) do
        {:ok, _, remainder, position} -> {:ok, :empty, remainder, position}
        x -> x
      end
    end
  end

  combinator "ignore" do
    fn target, option, position ->
      combinator_dump(combinator_option(option)).(target, position)
    end
  end

end
