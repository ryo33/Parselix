defmodule Parselix do

  defmacro __using__(_opts) do
    quote do
      import Parselix
      alias Parselix.Position, as: Position
      alias Parselix.Token, as: Token
      alias Parselix.AST, as: AST
    end
  end

  defmodule Position, do: defstruct index: 0, vertical: 0, horizontal: 0

  defmodule AST, do: defstruct label: nil, children: nil, position: %Position{}

  def get_position(current, target, consumed) when is_integer(consumed) do
    used = String.slice target, 0, consumed
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

  def get_position(current, target, remainder) when is_binary(remainder) do
    get_position current, target, String.length(target) - String.length(remainder)
  end

  defmacro position(index \\ 0, vertical \\ 0, horizontal \\ 0), do: quote do: %Position{index: unquote(index), vertical: unquote(vertical), horizontal: unquote(horizontal)}

  defmacro parser(name, do: block) do
    parser_name = String.to_atom(name)
    parser_l_name = String.to_atom(name <> "_l")
    quote do
      def unquote(parser_l_name)(option \\ nil) do
        fn target, current_position ->
          case (unquote(block)).(target, option, current_position) do
            {:ok, children, remainder, position} -> {:ok, %AST{label: unquote(name), children: children, position: current_position}, remainder, position}
            {:ok, children, remainder} when is_binary(remainder) -> {:ok, %AST{label: unquote(name), children: children, position: current_position}, remainder, get_position(current_position, target, remainder)}
            {:ok, children, consumed} when is_integer(consumed) ->
              {:ok,
                %AST{label: unquote(name), children: children, position: current_position
                }, String.slice(target, Range.new(consumed, -1)), get_position(current_position, target, consumed)}
            {:error, message, position} -> {:error, "[" <> unquote(name) <> "] " <> message, position}
            {:error, message} -> {:error, "[" <> unquote(name) <> "] " <> message, current_position}
            x -> {:error, "\"" <> unquote(name) <> "\" returns a misformed result.\n#{inspect x}", current_position}
          end
        end
      end
      def unquote(parser_name)(option \\ nil) do
        fn target, current_position ->
          case (unquote(block)).(target, option, current_position) do
            {:ok, children, remainder, position} = x -> x
            {:ok, children, remainder} when is_binary(remainder) -> {:ok, children, remainder, get_position(current_position, target, remainder)}
            {:ok, children, consumed} when is_integer(consumed) -> {:ok, children, String.slice(target, Range.new(consumed, -1)), get_position(current_position, target, consumed)}
            {:error, message, position} = x -> x
            {:error, message} -> {:error, message, current_position}
            x -> {:error, "\"" <> unquote(name) <> "\" returns a misformed result.\n#{inspect x}", current_position}
          end
        end
      end
    end
  end

end
