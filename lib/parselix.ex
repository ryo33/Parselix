defmodule Parselix do

  defmacro __using__(_opts) do
    quote do
      import Parselix
      alias Parselix.Position, as: Position
      alias Parselix.Token, as: Token
      alias Parselix.Meta, as: Meta
      alias Parselix.Basic, as: Basic
      alias Parselix.Common, as: Common
      alias Parselix.Prepared, as: Prepared
    end
  end

  defmodule Position, do: defstruct index: 0, vertical: 0, horizontal: 0

  defmodule Meta, do: defstruct label: nil, content: nil, position: %Position{}

  defmacro position(index \\ 0, vertical \\ 0, horizontal \\ 0), do: quote do: %Position{index: unquote(index), vertical: unquote(vertical), horizontal: unquote(horizontal)}

  def parse(parser, target, position \\ position) do
    parser.(target, position)
  end

  def get_position(current, target, consumed) when is_integer(consumed) do
    used = String.slice target, 0, consumed
    used_list = String.codepoints used
    a = fn x ->
      case x do
        nil -> []
        x -> x
      end
    end
    vertical = (used_list |> Enum.count fn x -> x == "\n" or x == "\r" end) - length(a.(Regex.run ~r/\r\n/, used))
    get_horizontal = fn
      [head | tail], count, get_horizontal -> case head do
        x when x == "\r" or x == "\n" -> get_horizontal.(tail, 0, get_horizontal)
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

  defmacro parser(name, do: block) do
    parser_name = String.to_atom(name)
    parser_l_name = String.to_atom(name <> "_l")
    quote do
      def unquote(parser_l_name)(option \\ nil) do
        fn target, current_position ->
          case (unquote(block)).(fn x -> apply(__MODULE__, unquote(parser_l_name), [x]) end, option, target, current_position) do
            {:ok, children, remainder, position} -> {:ok, %Meta{label: unquote(name), content: children, position: current_position}, remainder, position}
            {:ok, children, remainder} when is_binary(remainder) -> {:ok, %Meta{label: unquote(name), content: children, position: current_position}, remainder, get_position(current_position, target, remainder)}
            {:ok, children, consumed} when is_integer(consumed) ->
              {:ok,
                %Meta{label: unquote(name), content: children, position: current_position
                }, String.slice(target, Range.new(consumed, -1)), get_position(current_position, target, consumed)}
            {:error, message, position} -> {:error, "[" <> unquote(name) <> "] " <> message, position}
            {:error, message} -> {:error, "[" <> unquote(name) <> "] " <> message, current_position}
            x -> {:error, "\"" <> unquote(name) <> "\" returns a misformed result.\n#{inspect x}", current_position}
          end
        end
      end
      def unquote(parser_name)(option \\ nil) do
        fn target, current_position ->
          case (unquote(block)).(fn x -> apply(__MODULE__, unquote(parser_name), [x]) end, option, target, current_position) do
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
