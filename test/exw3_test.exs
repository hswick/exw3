defmodule EXW3Test do
  use ExUnit.Case
  doctest ExW3

  setup_all do
    %{
      simple_storage_abi: ExW3.load_abi("test/examples/build/SimpleStorage.abi"),
      array_tester_abi: ExW3.load_abi("test/examples/build/ArrayTester.abi"),
      event_tester_abi: ExW3.load_abi("test/examples/build/EventTester.abi"),
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

  test "mines a block" do
    block_number = ExW3.block_number
    ExW3.mine
    assert ExW3.block_number == block_number + 1 
  end

  test "mines multiple blocks" do
    block_number = ExW3.block_number
    ExW3.mine 5
    assert ExW3.block_number == block_number + 5
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

    {:ok, result} = ExW3.Contract.method storage, :get

    assert result == 0

    {:ok, tx_hash} = ExW3.Contract.method(storage, :set, [1], %{from: Enum.at(context[:accounts], 0)})

    {:ok, result} = ExW3.Contract.method storage, :get

    assert result == 1

  end

  test "deploys event tester and uses it", context do
    contract_address = ExW3.Contract.deploy(
      "test/examples/build/EventTester.bin",
      %{
        from: Enum.at(context[:accounts], 0),
        gas: 300000
      }
    )

    event_tester = ExW3.Contract.at context[:event_tester_abi], contract_address

    {:ok, tx_hash} = ExW3.Contract.method(
      event_tester, 
      :simple,
      ["Hello, World!"],
      %{from: Enum.at(context[:accounts], 0)}
    )

    {:ok, {receipt, logs}} = ExW3.Contract.tx_receipt(event_tester, tx_hash)

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> ExW3.bytes_to_string()

    assert data  == "Hello, World!"

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

    # This is supposed to fail
    # {:ok, result} = ExW3.Contract.method array_tester, :static_int, [arr]

    # assert result == arr

    #0x5d4e0342
    # This is currently failing
    {:ok, result} = ExW3.Contract.method array_tester, :dynamic_uint, [arr]

    assert result == arr

  end

end