defmodule ExW3.Utils do
  alias ExW3.Address

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
  def keccak256(str) do
    "0x#{str |> ExKeccak.hash_256() |> Base.encode16(case: :lower)}"
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

  @deprecated "Use ExW3.Address.to_checksum/1 instead."
  @doc "Returns a checksummed address conforming to EIP-55"
  @spec to_checksum_address(String.t()) :: String.t()
  def to_checksum_address(address) do
    address
    |> Address.from_hex()
    |> Address.to_checksum()
  end

  @deprecated "Use ExW3.Address.is_valid_checksum?/1 instead."
  @doc "Checks if the address is a valid checksummed address"
  @spec is_valid_checksum_address(String.t()) :: boolean
  def is_valid_checksum_address(address) do
    Address.is_valid_checksum?(address)
  end

  @doc "converts Ethereum style bytes to string"
  @spec bytes_to_string(binary()) :: binary()
  def bytes_to_string(bytes) do
    bytes
    |> Base.encode16(case: :lower)
    |> String.replace_trailing("0", "")
    |> Base.decode16!(case: :lower)
  end

  @doc "Converts an Ethereum address into a form that can be used by the ABI encoder"
  @spec format_address(binary()) :: integer()
  def format_address(address) do
    address
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> :binary.decode_unsigned()
  end

  @deprecated "Use ExW3.Address.to_hex/1 instead."
  @doc "Converts bytes to Ethereum address"
  @spec to_address(binary()) :: binary()
  def to_address(bytes) do
    bytes
    |> Address.from_bytes()
    |> Address.to_hex()
  end
end
