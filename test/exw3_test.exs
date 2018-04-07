defmodule EXW3Test do
  use ExUnit.Case
  doctest ExW3

  setup_all do
    %{
      simple_storage_abi: ExW3.load_abi("test/examples/build/SimpleStorage.abi"), 
      accounts: ExW3.accounts
    }
  end

  test "loads abi", context do
    assert context[:simple_storage_abi] |> is_map
  end

  test "deploys contract and uses it", context do
    contract_address = ExW3.Contract.deploy(
      "test/examples/build/SimpleStorage.bin", 
      %{
        from: Enum.at(context[:accounts], 0), 
        gas: 150000
      }
    )

    storage = ExW3.Contract.at context[:simple_storage_abi], contract_address

    {:ok, result} = ExW3.Contract.method(storage, "get")

    assert result == 0

    ExW3.Contract.method(storage, "set", [1], %{from: Enum.at(context[:accounts], 0)})

    {:ok, result} = ExW3.Contract.method(storage, "get")

    assert result == 1

  end

  test "gets accounts" do
    assert ExW3.accounts |> is_list
  end

end