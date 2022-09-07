defmodule ExW3.DynamoContractTest do
  use ExUnit.Case

  alias ExW3.DynamoContract
  alias ExW3.Contracts.ERC20

  alias ExW3.DummyRPC

  @dummy_address "0x100911110df37c9fb26829eb2cc623cd1bf50001"

  describe ".generate_module" do
    test "Generates the module with the given api functions" do
      assert {:module, AddressTester, _, _} =
               DynamoContract.generate_module(
                 AddressTester,
                 "test/examples/build/AddressTester.abi"
               )

      {:ok, address} = DynamoContract.decode16(@dummy_address)

      assert %{
               data: "0xc2bc2efc000000000000000000000000100911110df37c9fb26829eb2cc623cd1bf50001",
               selector: %{
                 method_id: <<194, 188, 46, 252>>
               }
             } = AddressTester.get(address)

      assert %{
               data:
                 <<194, 188, 46, 252, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 9, 17, 17, 13, 243,
                   124, 159, 178, 104, 41, 235, 44, 198, 35, 205, 27, 245, 0, 1>>,
               selector: %{
                 method_id: <<194, 188, 46, 252>>
               }
             } = AddressTester.get(address, data_as: :binary)
    end
  end

  describe ".call" do
    test "calling a function and fetching the result" do
      DummyRPC.mock_response(
        {:ok,
         "0x00000000000000000000000000000000000000000000000000000000000000200000" <>
           "00000000000000000000000000000000000000000000000000000000000e4574686572" <>
           "65756d20546f6b656e000000000000000000000000000000000000"}
      )

      assert {:ok, ["Ethereum Token"]} = ERC20.name() |> ERC20.call(to: @dummy_address)
    end

    test "calling a function causing an error" do
      DummyRPC.mock_response({:error, :cause})

      assert {:error, :cause} = ERC20.name() |> ERC20.call(to: @dummy_address)
    end
  end

  describe ".send" do
    test "sending a transaction and getting the tx info" do
      DummyRPC.mock_response(
        {:ok, "0x88838e84a401a1d6162290a1a765507c4a83f5e050658a83992a912f42149ca5"}
      )

      assert {:ok, <<"0x", _::binary>>} = ERC20.name() |> ERC20.send(to: @dummy_address)
    end
  end
end
