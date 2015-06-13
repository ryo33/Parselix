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

  defmodule AST, do: defstruct label: nil, tree: nil, position: %Position{}

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

  defmacro parser(name, do: block) do
    parse_name = String.to_atom("parser_" <> name)
    quote do
      def unquote(parse_name)(option) do
        fn target, current_position ->
          case (unquote(block)).(target, option, current_position) do
            {:ok, tree, remainder, position} -> {:ok, %AST{label: unquote(name), tree: tree, position: current_position}, remainder, position}
            {:ok, tree, remainder} -> {:ok, %AST{label: unquote(name), tree: tree, position: current_position}, remainder, get_position(current_position, target, remainder)}
            {:error, message} -> {:error, unquote(name) <> " " <> message}
            x -> {:error, unquote(name) <> " returns a misformed result", x}
          end
        end
      end
    end
  end

end
