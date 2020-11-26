defmodule EXW3.ContractTest do
  use ExUnit.Case
  doctest ExW3.Contract

  @simple_storage_abi ExW3.load_abi("test/examples/build/SimpleStorage.abi")

  setup_all do
    start_supervised!(ExW3.Contract)
    :ok
  end

  test ".at assigns the address to the state of the registered contract" do
    ExW3.Contract.register(:SimpleStorage, abi: @simple_storage_abi)

    assert ExW3.Contract.address(:SimpleStorage) == nil

    accounts = ExW3.accounts()

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :SimpleStorage,
        bin: ExW3.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert ExW3.Contract.at(:SimpleStorage, address) == :ok

    state = :sys.get_state(ContractManager)
    contract_state = state[:SimpleStorage]
    assert Keyword.get(contract_state, :address) == address
    assert Keyword.get(contract_state, :abi) == @simple_storage_abi
  end

  test ".address returns the registered address for the contract" do
    ExW3.Contract.register(:SimpleStorage, abi: @simple_storage_abi)

    assert ExW3.Contract.address(:SimpleStorage) == nil

    accounts = ExW3.accounts()

    {:ok, address, _} =
      ExW3.Contract.deploy(
        :SimpleStorage,
        bin: ExW3.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(accounts, 0)
        }
      )

    assert ExW3.Contract.at(:SimpleStorage, address) == :ok
    assert ExW3.Contract.address(:SimpleStorage) == address
  end
end
