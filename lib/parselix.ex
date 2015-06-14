defmodule Parselix do

  defmacro __using__(_opts) do
    quote do
      import Parselix
      alias Parselix.Position, as: Position
      alias Parselix.Token, as: Token
      alias Parselix.AST, as: AST
      import Parselix.Basic
    end
  end

  defmodule Position, do: defstruct index: 0, vertical: 0, horizontal: 0

  defmodule AST, do: defstruct label: nil, children: nil, position: %Position{}

  def get_position(current, target, remainder) do
    used = String.slice target, 0, String.length(target) - String.length(remainder)
    used_list = String.to_char_list used
    vertical = used_list |> Enum.count fn x -> x === ?\n end
    get_horizontal = fn
      [head | tail], count, get_horizontal -> case head do
        ?\n -> get_horizontal.(tail, 0, get_horizontal)
        _ -> get_horizontal.(tail, count + 1, get_horizontal)
      end
      [], count, _ -> count
    end
    horizontal = get_horizontal.(used_list, current.horizontal, get_horizontal)
    %Position{
      index: current.index + (String.length used),
      vertical: current.vertical + vertical,
      horizontal: horizontal
    }
  end

  def unwrap(%AST{children: %AST{} = children}), do: children

  def flat(children) do
    case children do
      [head | tail] -> flat(head) ++ flat(tail)
      %AST{children: children} -> flat(children)
      [] -> []
      x -> [x]
    end
  end

  defmacro parser(name, do: block) do
    parse_name = String.to_atom("parser_" <> name)
    quote do
      def unquote(parse_name)(option) do
        fn target, current_position ->
          case (unquote(block)).(target, option, current_position) do
            {:ok, children, remainder, position} -> {:ok, %AST{label: unquote(name), children: children, position: current_position}, remainder, position}
            {:ok, children, remainder} -> {:ok, %AST{label: unquote(name), children: children, position: current_position}, remainder, get_position(current_position, target, remainder)}
            {:error, message, position} -> {:error, "[" <> unquote(name) <> "] " <> message, position}
            {:error, message} -> {:error, "[" <> unquote(name) <> "] " <> message, current_position}
            x -> {:error, "[" <> unquote(name) <> "] returns a misformed result", current_position}
          end
        end
      end
    end
  end

end
