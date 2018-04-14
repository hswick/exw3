defmodule EXW3Test do
  use ExUnit.Case
  doctest ExW3

  setup_all do
    %{
      simple_storage_abi: ExW3.load_abi("test/examples/build/SimpleStorage.abi"),
      array_tester_abi: ExW3.load_abi("test/examples/build/ArrayTester.abi"),
      accounts: ExW3.accounts
    }
  end

  test "gets accounts" do
    assert ExW3.accounts |> is_list
  end

  test "gets balance", context do
    assert ExW3.balance(Enum.at context[:accounts], 0 ) |> is_integer
  end

  test "gets block number" do
    assert ExW3.block_number |> is_integer
  end

  test "loads abi", context do
    assert context[:simple_storage_abi] |> is_map
  end

  test "deploys simple storage and uses it", context do
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

    {:ok, tx_id} = ExW3.Contract.method(storage, "set", [1], %{from: Enum.at(context[:accounts], 0)})

    IO.inspect ExW3.tx_receipt tx_id

    {:ok, result} = ExW3.Contract.method(storage, "get")

    assert result == 1

  end

  test "deploys array tester and uses it", context do
    contract_address = ExW3.Contract.deploy(
      "test/examples/build/ArrayTester.bin", 
      %{
        from: Enum.at(context[:accounts], 0), 
        gas: 300000
      }
    )

    array_tester = ExW3.Contract.at context[:array_tester_abi], contract_address

    arr = [1, 2, 3, 4, 5]

    {:ok, result} = ExW3.Contract.method(array_tester, "staticUint", [arr])

    assert result == arr

    #0x5d4e0342
    {:ok, result} = ExW3.Contract.method(array_tester, "dynamicUint", [arr])

    assert result == arr

  end

end