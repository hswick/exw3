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

  @unit_map %{
    :noether => 0,
    :wei => 1,
    :kwei => 1_000,
    :Kwei => 1_000,
    :babbage => 1_000,
    :femtoether => 1_000,
    :mwei => 1_000_000,
    :Mwei => 1_000_000,
    :lovelace => 1_000_000,
    :picoether => 1_000_000,
    :gwei => 1_000_000_000,
    :Gwei => 1_000_000_000,
    :shannon => 1_000_000_000,
    :nanoether => 1_000_000_000,
    :nano => 1_000_000_000,
    :szabo => 1_000_000_000_000,
    :microether => 1_000_000_000_000,
    :micro => 1_000_000_000_000,
    :finney => 1_000_000_000_000_000,
    :milliether => 1_000_000_000_000_000,
    :milli => 1_000_000_000_000_000,
    :ether => 1_000_000_000_000_000_000,
    :kether => 1_000_000_000_000_000_000_000,
    :grand => 1_000_000_000_000_000_000_000,
    :mether => 1_000_000_000_000_000_000_000_000,
    :gether => 1_000_000_000_000_000_000_000_000_000,
    :tether => 1_000_000_000_000_000_000_000_000_000_000
  }

  @doc "Converts the value to whatever unit key is provided. See unit map for details."
  @spec to_wei(integer, atom) :: integer
  def to_wei(num, key) do
    if @unit_map[key] do
      num * @unit_map[key]
    else
      throw("#{key} not valid unit")
    end
  end

  @doc "Converts the value to whatever unit key is provided. See unit map for details."
  @spec from_wei(integer, atom) :: integer | float | no_return
  def from_wei(num, key) do
    if @unit_map[key] do
      num / @unit_map[key]
    else
      throw("#{key} not valid unit")
    end
  end

  @doc "Returns a checksummed address conforming to EIP-55"
  @spec to_checksum_address(String.t()) :: String.t()
  def to_checksum_address(address) do
    address = address |> String.downcase() |> String.replace(~r/^0x/, "")
    {:ok, hash_bin} = ExKeccak.hash_256(address)

    hash =
      hash_bin
      |> Base.encode16(case: :lower)
      |> String.replace(~r/^0x/, "")

    keccak_hash_list =
      hash
      |> String.split("", trim: true)
      |> Enum.map(fn x -> elem(Integer.parse(x, 16), 0) end)

    list_arr =
      for n <- 0..(String.length(address) - 1) do
        number = Enum.at(keccak_hash_list, n)

        cond do
          number >= 8 -> String.upcase(String.at(address, n))
          true -> String.downcase(String.at(address, n))
        end
      end

    "0x" <> List.to_string(list_arr)
  end
end
