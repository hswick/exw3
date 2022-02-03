defmodule ExW3.AddressTest do
  use ExUnit.Case
  alias ExW3.Address

  @bytes_address <<25, 154, 209, 226, 223, 37, 243, 29, 135, 172, 137, 205, 225, 158, 82, 44, 130, 62, 90, 166, 30>>
  @string_address "199ad1e2df25f31d87ac89cde19e522c823e5aa61e"
  @hex_address "0x199ad1e2df25f31d87ac89cde19e522c823e5aa61e"
  @checksum_address "0x199ad1E2dF25f31D87AC89cdE19E522c823E5AA61e"

  test ".from_bytes/1 returns an address struct" do
    address = Address.from_bytes(@bytes_address)
    assert address.bytes == @bytes_address
  end

  test ".from_hex/1 returns an address struct with and without the checksum" do
    address = Address.from_hex(@hex_address)
    assert address.bytes == @bytes_address

    from_checksum_address = Address.from_hex(@checksum_address)
    assert from_checksum_address.bytes == @bytes_address
  end

  test ".to_bytes/1 returns the bytes of the address struct" do
    address = %Address{bytes: @bytes_address}
    assert Address.to_bytes(address) == @bytes_address
  end

  test ".to_string/1 returns the hex encoded string without a 0x prefix" do
    address = %Address{bytes: @bytes_address}
    assert Address.to_string(address) == @string_address
  end

  test ".to_hex/1 returns the hex encoded string with a 0x prefix" do
    address = %Address{bytes: @bytes_address}
    assert Address.to_hex(address) == @hex_address
  end

  test ".to_checksum/1 returns the hex encoded string with a 0x prefix conforming to EIP-55" do
    address = %Address{bytes: @bytes_address}
    assert Address.to_checksum(address) == @checksum_address
  end

  test ".is_valid_checksum?/1 is true when it conforms to EIP-55" do
    assert Address.is_valid_checksum?(@checksum_address) == true
    assert Address.is_valid_checksum?(@hex_address) == false
  end
end
