defmodule Parselix.Prepared do
  use Parselix

  defmacro __using__(_opts) do
    quote do
      import Prepared
      alias Prepared.JSON, as: JSON
    end
  end

end
