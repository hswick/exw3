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

  describe ".to_wei/2" do
    test "converts a unit to_wei" do
      assert ExW3.Utils.to_wei(1, :wei) == 1
      assert ExW3.Utils.to_wei(1, :kwei) == 1_000
      assert ExW3.Utils.to_wei(1, :Kwei) == 1_000
      assert ExW3.Utils.to_wei(1, :babbage) == 1_000
      assert ExW3.Utils.to_wei(1, :mwei) == 1_000_000
      assert ExW3.Utils.to_wei(1, :Mwei) == 1_000_000
      assert ExW3.Utils.to_wei(1, :lovelace) == 1_000_000
      assert ExW3.Utils.to_wei(1, :gwei) == 1_000_000_000
      assert ExW3.Utils.to_wei(1, :Gwei) == 1_000_000_000
      assert ExW3.Utils.to_wei(1, :shannon) == 1_000_000_000
      assert ExW3.Utils.to_wei(1, :szabo) == 1_000_000_000_000
      assert ExW3.Utils.to_wei(1, :finney) == 1_000_000_000_000_000
      assert ExW3.Utils.to_wei(1, :ether) == 1_000_000_000_000_000_000
      assert ExW3.Utils.to_wei(1, :kether) == 1_000_000_000_000_000_000_000
      assert ExW3.Utils.to_wei(1, :grand) == 1_000_000_000_000_000_000_000
      assert ExW3.Utils.to_wei(1, :mether) == 1_000_000_000_000_000_000_000_000
      assert ExW3.Utils.to_wei(1, :gether) == 1_000_000_000_000_000_000_000_000_000
      assert ExW3.Utils.to_wei(1, :tether) == 1_000_000_000_000_000_000_000_000_000_000

      assert ExW3.Utils.to_wei(1, :kwei) == ExW3.Utils.to_wei(1, :femtoether)
      assert ExW3.Utils.to_wei(1, :szabo) == ExW3.Utils.to_wei(1, :microether)
      assert ExW3.Utils.to_wei(1, :finney) == ExW3.Utils.to_wei(1, :milliether)
      assert ExW3.Utils.to_wei(1, :milli) == ExW3.Utils.to_wei(1, :milliether)
      assert ExW3.Utils.to_wei(1, :milli) == ExW3.Utils.to_wei(1000, :micro)

      {:ok, agent} = Agent.start_link(fn -> false end)

      try do
        ExW3.Utils.to_wei(1, :wei1)
      catch
        _ -> Agent.update(agent, fn _ -> true end)
      end

      assert Agent.get(agent, fn state -> state end)
    end
  end

  describe ".from_wei/2" do
    test "converts a unit from wei" do
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :wei) == 1_000_000_000_000_000_000
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :kwei) == 1_000_000_000_000_000
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :mwei) == 1_000_000_000_000
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :gwei) == 1_000_000_000
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :szabo) == 1_000_000
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :finney) == 1_000
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :ether) == 1
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :kether) == 0.001
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :grand) == 0.001
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :mether) == 0.000001
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :gether) == 0.000000001
      assert ExW3.Utils.from_wei(1_000_000_000_000_000_000, :tether) == 0.000000000001
    end
  end

  describe ".to_checksum_address/1" do
    test "returns checksum for all caps address" do
      assert ExW3.Utils.to_checksum_address(
               String.downcase("0x52908400098527886E0F7030069857D2E4169EE7")
             ) ==
               "0x52908400098527886E0F7030069857D2E4169EE7"

      assert ExW3.Utils.to_checksum_address(
               String.downcase("0x8617E340B3D01FA5F11F306F4090FD50E238070D")
             ) ==
               "0x8617E340B3D01FA5F11F306F4090FD50E238070D"
    end

    test "returns checksumfor all lowercase address" do
      assert ExW3.Utils.to_checksum_address(
               String.downcase("0xde709f2102306220921060314715629080e2fb77")
             ) ==
               "0xde709f2102306220921060314715629080e2fb77"

      assert ExW3.Utils.to_checksum_address(
               String.downcase("0x27b1fdb04752bbc536007a920d24acb045561c26")
             ) ==
               "0x27b1fdb04752bbc536007a920d24acb045561c26"
    end

    test "returns checksum for normal addresses" do
      assert ExW3.Utils.to_checksum_address(
               String.downcase("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed")
             ) ==
               "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"

      assert ExW3.Utils.to_checksum_address(
               String.downcase("0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")
             ) ==
               "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"

      assert ExW3.Utils.to_checksum_address(
               String.downcase("0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB")
             ) ==
               "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"

      assert ExW3.Utils.to_checksum_address(
               String.downcase("0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb")
             ) ==
               "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"
    end
  end

  describe ".is_valid_checksum_address/1" do
    test "returns valid check for is_valid_checksum_address()" do
      assert ExW3.Utils.is_valid_checksum_address("0x52908400098527886E0F7030069857D2E4169EE7") ==
               true

      assert ExW3.Utils.is_valid_checksum_address("0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB") ==
               true

      assert ExW3.Utils.is_valid_checksum_address("0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb") ==
               true

      assert ExW3.Utils.is_valid_checksum_address("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed") ==
               true

      assert ExW3.Utils.is_valid_checksum_address("0x27b1fdb04752bbc536007a920d24acb045561c26") ==
               true

      assert ExW3.Utils.is_valid_checksum_address("0xde709f2102306220921060314715629080e2fb77") ==
               true

      assert ExW3.Utils.is_valid_checksum_address("0x8617E340B3D01FA5F11F306F4090FD50E238070D") ==
               true

      assert ExW3.Utils.is_valid_checksum_address("0x52908400098527886E0F7030069857D2E4169EE7") ==
               true
    end

    test "returns invalid check for is_valid_checksum_address()" do
      assert ExW3.Utils.is_valid_checksum_address("0x2f015c60e0be116b1f0cd534704db9c92118fb6a") ==
               false
    end
  end
end
