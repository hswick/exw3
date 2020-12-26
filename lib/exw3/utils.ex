defmodule ExW3.Utils do
  @type invalid_hex_string :: :invalid_hex_string
  @type negative_integer :: :negative_integer
  @type non_integer :: :non_integer
  @type eth_hex :: String.t()

  @doc "Convert eth hex string to integer"
  @spec hex_to_integer(eth_hex) ::
          {:ok, non_neg_integer} | {:error, invalid_hex_string}
  def hex_to_integer(hex) do
    case hex do
      "0x" <> hex -> {:ok, String.to_integer(hex, 16)}
      _ -> {:error, :invalid_hex_string}
    end
  rescue
    ArgumentError ->
      {:error, :invalid_hex_string}
  end

  @doc "Convert an integer to eth hex string"
  @spec integer_to_hex(non_neg_integer) ::
          {:ok, eth_hex} | {:error, negative_integer | non_integer}
  def integer_to_hex(i) do
    case i do
      i when i < 0 -> {:error, :negative_integer}
      i -> {:ok, "0x" <> Integer.to_string(i, 16)}
    end
  rescue
    ArgumentError ->
      {:error, :non_integer}
  end

  @doc "Returns a 0x prepended 32 byte hash of the input string"
  @spec keccak256(String.t()) :: String.t()
  def keccak256(string) do
    {:ok, hash} = ExKeccak.hash_256(string)
    "0x#{Base.encode16(hash, case: :lower)}"
  end
end
