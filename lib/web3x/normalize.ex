defmodule Web3x.Normalize do
  @spec transform_to_integer(map(), list()) :: map()
  def transform_to_integer(map, keys) do
    for k <- keys, into: %{} do
      {:ok, v} = map |> Map.get(k) |> Web3x.Utils.hex_to_integer()
      {k, v}
    end
  end
end
