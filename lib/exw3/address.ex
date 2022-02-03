defmodule ExW3.Address do
  @type t :: %__MODULE__{bytes: binary}

  defstruct ~w[bytes]a

  @spec from_bytes(binary) :: t
  def from_bytes(bytes) do
    %__MODULE__{bytes: bytes}
  end

  @spec from_hex(String.t()) :: t
  def from_hex(address) do
    case address do
      "0x" <> a ->
        from_hex(a)

      a ->
        bytes = a |> String.downcase() |> Base.decode16!(case: :lower)
        %__MODULE__{bytes: bytes}
    end
  end

  @spec to_bytes(t) :: binary
  def to_bytes(%__MODULE__{bytes: bytes}) do
    bytes
  end

  @spec to_string(t) :: String.t()
  def to_string(%__MODULE__{bytes: bytes}) do
    Base.encode16(bytes, case: :lower)
  end

  @spec to_hex(t) :: String.t()
  def to_hex(%__MODULE__{} = address) do
    "0x#{__MODULE__.to_string(address)}"
  end

  @spec to_checksum(t) :: String.t()
  def to_checksum(%__MODULE__{} = address) do
    address = address |> __MODULE__.to_string()
    address_hash = address |> ExKeccak.hash_256() |> Base.encode16(case: :lower)

    keccak_hash_list =
      address_hash
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

  @spec is_valid_checksum?(String.t()) :: boolean
  def is_valid_checksum?(hex_address) do
    address = hex_address |> __MODULE__.from_hex()
    __MODULE__.to_checksum(address) == hex_address
  end
end

