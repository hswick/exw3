defmodule ExW3.UtilsTest do
  use ExUnit.Case
  doctest ExW3.Utils

  describe ".hex_to_integer/1" do
    test "parses a hex encoded string to an integer" do
      assert ExW3.Utils.hex_to_integer("0x1") == {:ok, 1}
      assert ExW3.Utils.hex_to_integer("0x2") == {:ok, 2}
      assert ExW3.Utils.hex_to_integer("0x2a") == {:ok, 42}
      assert ExW3.Utils.hex_to_integer("0x2A") == {:ok, 42}
    end

    test "returns an error when the string is not a valid hexidecimal" do
      assert ExW3.Utils.hex_to_integer("0x") == {:error, :invalid_hex_string}
      assert ExW3.Utils.hex_to_integer("0a") == {:error, :invalid_hex_string}
      assert ExW3.Utils.hex_to_integer("0xZ") == {:error, :invalid_hex_string}
    end
  end

  describe ".integer_to_hex/1" do
    test "encodes an integer to hexadecimal" do
      assert ExW3.Utils.integer_to_hex(1) == {:ok, "0x1"}
      assert ExW3.Utils.integer_to_hex(2) == {:ok, "0x2"}
      assert ExW3.Utils.integer_to_hex(42) == {:ok, "0x2A"}
    end

    test "returns an error when the integer is negative" do
      assert ExW3.Utils.integer_to_hex(-1) == {:error, :negative_integer}
    end

    test "returns an error when the value is not an integer" do
      assert ExW3.Utils.integer_to_hex(1.1) == {:error, :non_integer}
    end
  end

  describe ".keccak256/1" do
    test "returns a 0x prepended 32 byte hash of the input" do
      hex_hash = ExW3.Utils.keccak256("foo")
      assert "0x" <> hash = hex_hash
      assert hash == "41b1a0649752af1b28b3dc29a1556eee781e4a4c3a1f7f53f90fa834de098c4d"

      num_bytes = byte_size(hash)
      assert trunc(num_bytes / 2) == 32
    end
  end
end
