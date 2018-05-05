defmodule EXW3Test do
  use ExUnit.Case
  doctest ExW3

  setup_all do
    %{
      simple_storage_abi: ExW3.load_abi("test/examples/build/SimpleStorage.abi"),
      array_tester_abi: ExW3.load_abi("test/examples/build/ArrayTester.abi"),
      event_tester_abi: ExW3.load_abi("test/examples/build/EventTester.abi"),
      complex_abi: ExW3.load_abi("test/examples/build/Complex.abi"),
      accounts: ExW3.accounts()
    }
  end

  test "gets accounts" do
    assert ExW3.accounts() |> is_list
  end

  test "gets balance", context do
    assert ExW3.balance(Enum.at(context[:accounts], 0)) |> is_integer
  end

  test "gets block number" do
    assert ExW3.block_number() |> is_integer
  end

  test "loads abi", context do
    assert context[:simple_storage_abi] |> is_map
  end

  test "mines a block" do
    block_number = ExW3.block_number()
    ExW3.mine()
    assert ExW3.block_number() == block_number + 1
  end

  test "mines multiple blocks" do
    block_number = ExW3.block_number()
    ExW3.mine(5)
    assert ExW3.block_number() == block_number + 5
  end

  test "starts a Contract GenServer for simple storage contract", context do
    ExW3.Contract.start_link(SimpleStorage, abi: context[:simple_storage_abi])

    {:ok, address} =
      ExW3.Contract.deploy(
        SimpleStorage,
        bin: ExW3.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(SimpleStorage, address)

    assert address == ExW3.Contract.address(SimpleStorage)

    {:ok, data} = ExW3.Contract.call(SimpleStorage, :get)

    assert data == 0

    ExW3.Contract.send(SimpleStorage, :set, [1], %{from: Enum.at(context[:accounts], 0)})

    {:ok, data} = ExW3.Contract.call(SimpleStorage, :get)

    assert data == 1
  end

  test "starts a Contract GenServer for array tester contract", context do
    ExW3.Contract.start_link(ArrayTester, abi: context[:array_tester_abi])

    {:ok, address} =
      ExW3.Contract.deploy(
        ArrayTester,
        bin: ExW3.load_bin("test/examples/build/ArrayTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(ArrayTester, address)

    assert address == ExW3.Contract.address(ArrayTester)

    arr = [1, 2, 3, 4, 5]

    {:ok, result} = ExW3.Contract.call(ArrayTester, :staticUint, [arr])

    assert result == arr

    {:ok, result} = ExW3.Contract.call(ArrayTester, :dynamicUint, [arr])

    assert result == arr
  end

  test "starts a Contract GenServer for event tester contract", context do
    ExW3.Contract.start_link(EventTester, abi: context[:event_tester_abi])

    {:ok, address} =
      ExW3.Contract.deploy(
        EventTester,
        bin: ExW3.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(EventTester, address)

    assert address == ExW3.Contract.address(EventTester)

    {:ok, tx_hash} =
      ExW3.Contract.send(EventTester, :simple, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0)
      })

    {:ok, {receipt, logs}} = ExW3.Contract.tx_receipt(EventTester, tx_hash)

    assert receipt |> is_map

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> ExW3.bytes_to_string()

    assert data == "Hello, World!"
  end

  test "starts a Contract GenServer for Complex contract", context do
    ExW3.Contract.start_link(Complex, abi: context[:complex_abi])

    {:ok, address} =
      ExW3.Contract.deploy(
        Complex,
        bin: ExW3.load_bin("test/examples/build/Complex.bin"),
        args: [42, "Hello, world!"],
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    ExW3.Contract.at(Complex, address)

    assert address == ExW3.Contract.address(Complex)

    {:ok, foo, foobar} = ExW3.Contract.call(Complex, :getBoth)

    assert foo == 42

    assert ExW3.bytes_to_string(foobar) == "Hello, world!"
  end
end
