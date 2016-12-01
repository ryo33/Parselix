defmodule Parselix do
  @moduledoc """
  Provides the macro for creating parser and some helper functions.

  ## Examples

  ### Function style
      @doc "Replaces error messages."
      def error_message(parser, message) do
        fn target, position ->
          case parser.(target, position) do
            {:error, _, _} -> {:error, message, position}
            x -> x
          end
        end
      end

      @doc "Parse lowercase characters."
      def lowercases do
        fn target, position do
          parser = lowercase() |> many_1()
          parser.(target, position)
        end
      end

  ### Function style with parser_body macro
      @doc "Parse uppercase characters."
      def uppercases do
        parser_body do
          uppercase() |> many_1()
        end
      end

  ### Macro style
      @doc "Picks one value from the result of the given parser."
      parser :pick, [parser, index] do
        parser |> map(&Enum.at(&1, index))
      end

      @doc "Parses the end of text."
      parser :eof do
        fn
          "", position -> {:ok, :eof, "", position}
          _, position -> {:error, "There is not EOF.", position}
        end
      end

      # Private
      parserp :private_dump, [parser] do
        parser |> map(fn _ -> :empty end)
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Parselix
      alias Parselix.Position
      alias Parselix.Meta
    end
  end

  defmodule Position, do: defstruct index: 0, vertical: 0, horizontal: 0

  defmodule Meta, do: defstruct label: nil, value: nil, position: %Position{}

  @typedoc """
  A successful result.

  `{:ok, RESULT, REMAINDER, NEW_POSITION}`
  """
  @type ok :: {:ok, any, String.t, %Position{}}
  @typedoc """
  A failed result.

  `{:error, ERROR_MESSAGE, POSITION}`
  """
  @type error :: {:error, String.t, %Position{}}
  @type parser :: (String.t, %Position{} -> ok | error)

  def position(index \\ 0, vertical \\ 0, horizontal \\ 0), do: %Position{index: index, vertical: vertical, horizontal: horizontal}

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
    vertical = (used_list |> Enum.count(fn x -> x == "\n" or x == "\r" end)) - length(a.(Regex.run ~r/\r\n/, used))
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

  def format_result(result, name \\ nil, target, current_position) do
    name = if is_nil(name), do: "A parser", else: "\"#{name}\""
    case result do
      {:ok, _, _, _} = x -> x
      {:ok, children, remainder} when is_binary(remainder) ->
        {:ok, children, remainder, get_position(current_position, target, remainder)}
      {:ok, children, consumed} when is_integer(consumed) ->
        {:ok, children, String.slice(target, Range.new(consumed, -1)), get_position(current_position, target, consumed)}
      {:error, _, _} = x -> x
      {:error, message} -> {:error, message, current_position}
      x -> {:error, "#{name} returns a misformed result.\n#{inspect x}", current_position}
    end
  end

  @doc """
  Wraps a parser body.
  """
  defmacro parser_body(do: block) do
    quote do
      fn target, position ->
        parser = unquote(block)
        parser.(target, position)
      end
    end
  end
  @doc """
  Defines a parser.
  """
  defmacro parser(name, argument_names \\ [], do: block) do
    quote do
      def unquote(name)(unquote_splicing(argument_names)) do
        parser_body do: unquote(block)
      end
    end
  end

  @doc """
  Defines a private parser.
  """
  defmacro parserp(name, argument_names \\ [], do: block) do
    quote do
      defp unquote(name)(unquote_splicing(argument_names)) do
        parser_body do: unquote(block)
      end
    end
  end
end
