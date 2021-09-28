defmodule EXW3.ContractTest do
  use ExUnit.Case
  doctest Web3x.Contract

  @simple_storage_abi Web3x.Abi.load_abi("test/examples/build/SimpleStorage.abi")
  @mycollectible_abi Web3x.Abi.load_hardhat_abi("test/examples/build/MyCollectibleErc721.json")

  setup_all do
    start_supervised!(Web3x.Contract)
    :ok
  end

  test ".at assigns the address to the state of the registered contract" do
    Web3x.Contract.register(:SimpleStorage, abi: @simple_storage_abi)

    assert Web3x.Contract.address(:SimpleStorage) == nil

    accounts = Web3x.accounts()

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :SimpleStorage,
        bin: Web3x.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert Web3x.Contract.at(:SimpleStorage, address) == :ok

    state = :sys.get_state(ContractManager)
    contract_state = state[:SimpleStorage]
    assert Keyword.get(contract_state, :address) == address
    assert Keyword.get(contract_state, :abi) == @simple_storage_abi
  end

  test ".address returns the registered address for the contract" do
    Web3x.Contract.register(:SimpleStorage, abi: @simple_storage_abi)

    assert Web3x.Contract.address(:SimpleStorage) == nil

    accounts = Web3x.accounts()

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :SimpleStorage,
        bin: Web3x.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert Web3x.Contract.at(:SimpleStorage, address) == :ok
    assert Web3x.Contract.address(:SimpleStorage) == address
  end

  test ".deploy Mycollectible" do
    Web3x.Contract.register(:MyCollectibleErc721, abi: @mycollectible_abi)
    accounts = Web3x.accounts()

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :MyCollectibleErc721,
        bin: Web3x.Abi.load_hardhat_bin("test/examples/build/MyCollectibleErc721.json"),
        args: [],
        options: %{
          gas: 8_000_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert Web3x.Contract.at(:MyCollectibleErc721, address) == :ok
    assert Web3x.Contract.address(:MyCollectibleErc721) == address
  end

  test ".call for string return type returns string" do
    Web3x.Contract.register(:MyCollectibleErc721, abi: @mycollectible_abi)
    accounts = Web3x.accounts()

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :MyCollectibleErc721,
        bin: Web3x.Abi.load_hardhat_bin("test/examples/build/MyCollectibleErc721.json"),
        args: [],
        options: %{
          gas: 8_000_000,
          from: Enum.at(accounts, 0)
        }
      )

    Web3x.Contract.at(:MyCollectibleErc721, address)
    response = Web3x.Contract.call(:MyCollectibleErc721, :symbol, [])
    IO.inspect(response)
    assert {:ok, _} = response
  end
end
