defmodule Web3xTest do
  use ExUnit.Case
  doctest Web3x

  setup_all do
    start_supervised!(Web3x.Contract)

    %{
      simple_storage_abi: Web3x.Abi.load_abi("test/examples/build/SimpleStorage.abi"),
      array_tester_abi: Web3x.Abi.load_abi("test/examples/build/ArrayTester.abi"),
      event_tester_abi: Web3x.Abi.load_abi("test/examples/build/EventTester.abi"),
      complex_abi: Web3x.Abi.load_abi("test/examples/build/Complex.abi"),
      address_tester_abi: Web3x.Abi.load_abi("test/examples/build/AddressTester.abi"),
      accounts: Web3x.accounts()
    }
  end

  # Only works with ganache-cli

  # test "mines a block" do
  #   block_number = Web3x.block_number()
  #   Web3x.mine()
  #   assert Web3x.block_number() == block_number + 1
  # end

  # test "mines multiple blocks" do
  #   block_number = Web3x.block_number()
  #   Web3x.mine(5)
  #   assert Web3x.block_number() == block_number + 5
  # end

  test "starts a Contract GenServer for simple storage contract", context do
    Web3x.Contract.register(:SimpleStorage, abi: context[:simple_storage_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :SimpleStorage,
        bin: Web3x.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    Web3x.Contract.at(:SimpleStorage, address)

    assert address == Web3x.Contract.address(:SimpleStorage)

    {:ok, data} = Web3x.Contract.call(:SimpleStorage, :get)

    assert data == 0

    Web3x.Contract.send(:SimpleStorage, :set, [1], %{
      from: Enum.at(context[:accounts], 0),
      gas: 50_000
    })

    {:ok, data} = Web3x.Contract.call(:SimpleStorage, :get)

    assert data == 1
  end

  test "starts a Contract GenServer for array tester contract", context do
    Web3x.Contract.register(:ArrayTester, abi: context[:array_tester_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :ArrayTester,
        bin: Web3x.Abi.load_bin("test/examples/build/ArrayTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    Web3x.Contract.at(:ArrayTester, address)

    assert address == Web3x.Contract.address(:ArrayTester)

    arr = [1, 2, 3, 4, 5]

    {:ok, result} = Web3x.Contract.call(:ArrayTester, :staticUint, [arr])

    assert result == arr

    {:ok, result} = Web3x.Contract.call(:ArrayTester, :dynamicUint, [arr])

    assert result == arr
  end

  test "starts a Contract GenServer for event tester contract", context do
    Web3x.Contract.register(:EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :EventTester,
        bin: Web3x.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    Web3x.Contract.at(:EventTester, address)

    assert address == Web3x.Contract.address(:EventTester)

    {:ok, tx_hash} =
      Web3x.Contract.send(:EventTester, :simple, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, {receipt, logs}} = Web3x.Contract.tx_receipt(:EventTester, tx_hash)

    assert receipt |> is_map

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> Web3x.Utils.bytes_to_string()

    assert data == "Hello, World!"

    {:ok, tx_hash2} =
      Web3x.Contract.send(:EventTester, :simpleIndex, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, {_receipt, logs}} = Web3x.Contract.tx_receipt(:EventTester, tx_hash2)

    otherNum =
      logs
      |> Enum.at(0)
      |> Map.get("otherNum")

    assert otherNum == 42

    num =
      logs
      |> Enum.at(0)
      |> Map.get("num")

    assert num == 46

    data =
      logs
      |> Enum.at(0)
      |> Map.get("data")
      |> Web3x.Utils.bytes_to_string()

    assert data == "Hello, World!"
  end

  test "Testing formatted get filter changes", context do
    Web3x.Contract.register(:EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :EventTester,
        bin: Web3x.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    Web3x.Contract.at(:EventTester, address)

    # Test non indexed events

    {:ok, filter_id} = Web3x.Contract.filter(:EventTester, "Simple")

    {:ok, _tx_hash} =
      Web3x.Contract.send(
        :EventTester,
        :simple,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = Web3x.Contract.get_filter_changes(filter_id)

    event_log = Enum.at(change_logs, 0)

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 42
    assert Web3x.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"

    Web3x.Contract.uninstall_filter(filter_id)

    # Test indexed events

    {:ok, indexed_filter_id} = Web3x.Contract.filter(:EventTester, "SimpleIndex")

    {:ok, _tx_hash} =
      Web3x.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = Web3x.Contract.get_filter_changes(indexed_filter_id)

    event_log = Enum.at(change_logs, 0)

    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert Web3x.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42
    Web3x.Contract.uninstall_filter(indexed_filter_id)

    # Test Indexing Indexed Events

    {:ok, indexed_filter_id} =
      Web3x.Contract.filter(
        :EventTester,
        "SimpleIndex",
        %{
          topics: [nil, ["Hello, World", "Hello, World!"]],
          fromBlock: 1,
          toBlock: "latest"
        }
      )

    {:ok, _tx_hash} =
      Web3x.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    {:ok, change_logs} = Web3x.Contract.get_filter_changes(indexed_filter_id)

    event_log = Enum.at(change_logs, 0)
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert Web3x.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    Web3x.Contract.uninstall_filter(indexed_filter_id)

    # Tests filter with map params

    {:ok, indexed_filter_id} =
      Web3x.Contract.filter(
        :EventTester,
        "SimpleIndex",
        %{
          topics: %{num: 46, data: "Hello, World!"}
        }
      )

    {:ok, _tx_hash} =
      Web3x.Contract.send(
        :EventTester,
        :simpleIndex,
        ["Hello, World!"],
        %{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )

    # Demonstrating the delay capability
    {:ok, change_logs} = Web3x.Contract.get_filter_changes(indexed_filter_id)

    event_log = Enum.at(change_logs, 0)
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 46
    assert Web3x.Utils.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"
    assert Map.get(log_data, "otherNum") == 42

    Web3x.Contract.uninstall_filter(indexed_filter_id)
  end

  test "starts a Contract GenServer for Complex contract", context do
    Web3x.Contract.register(:Complex, abi: context[:complex_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :Complex,
        bin: Web3x.Abi.load_bin("test/examples/build/Complex.bin"),
        args: [42, "Hello, world!"],
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    Web3x.Contract.at(:Complex, address)

    assert address == Web3x.Contract.address(:Complex)

    {:ok, foo, foobar} = Web3x.Contract.call(:Complex, :getBoth)

    assert foo == 42

    assert Web3x.Utils.bytes_to_string(foobar) == "Hello, world!"
  end

  test "starts a Contract GenServer for AddressTester contract", context do
    Web3x.Contract.register(:AddressTester, abi: context[:address_tester_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :AddressTester,
        bin: Web3x.Abi.load_bin("test/examples/build/AddressTester.bin"),
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    Web3x.Contract.at(:AddressTester, address)

    assert address == Web3x.Contract.address(:AddressTester)

    formatted_address =
      Enum.at(context[:accounts], 0)
      |> Web3x.Utils.format_address()

    {:ok, same_address} = Web3x.Contract.call(:AddressTester, :get, [formatted_address])

    assert Web3x.Utils.to_address(same_address) == Enum.at(context[:accounts], 0)
  end

  test "returns proper error messages at contract deployment", context do
    Web3x.Contract.register(:SimpleStorage, abi: context[:simple_storage_abi])

    assert {:error, :missing_gas} ==
             Web3x.Contract.deploy(
               :SimpleStorage,
               bin: Web3x.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
               args: [],
               options: %{
                 from: Enum.at(context[:accounts], 0)
               }
             )

    assert {:error, :missing_sender} ==
             Web3x.Contract.deploy(
               :SimpleStorage,
               bin: Web3x.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
               args: [],
               options: %{
                 gas: 300_000
               }
             )

    assert {:error, :missing_binary} ==
             Web3x.Contract.deploy(
               :SimpleStorage,
               args: [],
               options: %{
                 gas: 300_000,
                 from: Enum.at(context[:accounts], 0)
               }
             )
  end

  test "return proper error messages at send and call", context do
    Web3x.Contract.register(:SimpleStorage, abi: context[:simple_storage_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :SimpleStorage,
        bin: Web3x.Abi.load_bin("test/examples/build/SimpleStorage.bin"),
        args: [],
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    assert {:error, :missing_address} == Web3x.Contract.call(:SimpleStorage, :get)

    assert {:error, :missing_address} ==
             Web3x.Contract.send(:SimpleStorage, :set, [1], %{
               from: Enum.at(context[:accounts], 0),
               gas: 50_000
             })

    Web3x.Contract.at(:SimpleStorage, address)

    assert {:error, :missing_sender} ==
             Web3x.Contract.send(:SimpleStorage, :set, [1], %{gas: 50_000})

    assert {:error, :missing_gas} ==
             Web3x.Contract.send(:SimpleStorage, :set, [1], %{from: Enum.at(context[:accounts], 0)})
  end

  test ".get_logs/1", context do
    Web3x.Contract.register(:EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      Web3x.Contract.deploy(
        :EventTester,
        bin: Web3x.Abi.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    Web3x.Contract.at(:EventTester, address)

    {:ok, current_block} = Web3x.block_number()
    {:ok, from_block} = Web3x.Utils.integer_to_hex(current_block)

    {:ok, simple_tx_hash} =
      Web3x.Contract.send(:EventTester, :simple, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    {:ok, _} =
      Web3x.Contract.send(:EventTester, :simpleIndex, ["Hello, World!"], %{
        from: Enum.at(context[:accounts], 0),
        gas: 30_000
      })

    filter = %{
      fromBlock: from_block,
      toBlock: "latest",
      topics: [Web3x.Utils.keccak256("Simple(uint256,bytes32)")]
    }

    assert {:ok, logs} = Web3x.get_logs(filter)
    assert Enum.count(logs) == 1

    log = Enum.at(logs, 0)
    assert log["transactionHash"] == simple_tx_hash
  end
end
