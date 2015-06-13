defmodule Parselix.Basic do
  import Parselix

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

end
