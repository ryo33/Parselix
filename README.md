# Parselix
A parser combinator library for Elixir.  
[![hex.pm version](https://img.shields.io/hexpm/v/parselix.svg)](https://hex.pm/packages/parselix)

## Document
[Parselix Document](https://hexdocs.pm/parselix/)  

## Features
* Attaching Metadata(position and token name)
* Evaluating While Parsing
* Recursive Parser
* Combining Small Parsers
* Editable Error Messages
* Documentable

## For what?
* To **parse** languages, data formats, and more.  
* To **format** strings.  
* To **validate** something such as mail address.  

## Installation
Add `{:parselix, "~> x.x.x"}` to deps of your app.

## Example

### JSON
[See the json parser implementation by Parselix](https://github.com/ryo33/Parselix/blob/master/lib/parselix/prepared/json.ex).  


### Function style
```elixir
@doc "Replaces error messages."
def error_message(parser, message) do
  fn target, position ->
    case parser.(target, position) do
      {:error, _, _} -> {:error, message, position}
      x -> x
    end
  end
end
```

```elixir
@doc "Parse lowercase characters."
def lowercases do
  fn target, position do
    parser = lowercase() |> many_1()
    parser.(target, position)
  end
end
```

### Function style with parser_body macro
```elixir
@doc "Parse uppercase characters."
def uppercases do
  parser_body do
    uppercase() |> many_1()
  end
end
```

# Macro style
```elixir
@doc "Picks one value from the result of the given parser."
parser :pick, [parser, index] do
  parser |> map(&Enum.at(&1, index))
end
```

```elixir
@doc "Parses the end of text."
parser :eof do
  fn
    "", position -> {:ok, :eof, "", position}
    _, position -> {:error, "There is not EOF.", position}
  end
end
```

# Private
```elixir
parserp :private_dump, [parser] do
  parser |> map(fn _ -> :empty end)
end
```

## License
  MIT

## Author
  [ryo33](https://github.com/ryo33/ "ryo33's github page")
