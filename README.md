# Parselix
A parser combinator library for Elixir.  
[![hex.pm version](https://img.shields.io/hexpm/v/parselix.svg)](https://hex.pm/packages/parselix)

###Document
[Parselix Document](http://hexdocs.pm/parselix/0.1.0/)  

###For what?
* To **parse** languages, data formats, and more.  
* To **format** strings.  
* To **validate** something such as mail address.  

###Installation
Add `{:parselix, "~> 0.1.0"}` to deps of your app.

###Example
[See the json parser implementation by Parselix](lib/parselix/prepared/json.ex).  
And, see the following its usage.  
```
iex> use Parselix
iex> use Parselix.Prepared.JSON
iex> json |> parse("{\"name\": \"Parselix\"}")
{:ok, %{"name" => "Parselix"}, "",
 %Parselix.Position{horizontal: 20, index: 20, vertical: 0}}
iex> json |> parse("{\"name\": \"Parselix}")
{:error, "No parser succeeded.",
 %Parselix.Position{horizontal: 0, index: 0, vertical: 0}}
```

###License
  MIT

###Author
  [ryo33](https://github.com/ryo33/ "ryo33's github page")
