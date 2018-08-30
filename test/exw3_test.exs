defmodule EXW3Test do
  use ExUnit.Case
  doctest ExW3

  setup_all do
    %{
      simple_storage_abi: ExW3.load_abi("test/examples/build/SimpleStorage.abi"),
      array_tester_abi: ExW3.load_abi("test/examples/build/ArrayTester.abi"),
      event_tester_abi: ExW3.load_abi("test/examples/build/EventTester.abi"),
      complex_abi: ExW3.load_abi("test/examples/build/Complex.abi"),
      address_tester_abi: ExW3.load_abi("test/examples/build/AddressTester.abi"),
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

  # Only works with ganache-cli
  
  # test "mines a block" do
  #   block_number = ExW3.block_number()
  #   ExW3.mine()
  #   assert ExW3.block_number() == block_number + 1
  # end

  # test "mines multiple blocks" do
  #   block_number = ExW3.block_number()
  #   ExW3.mine(5)
  #   assert ExW3.block_number() == block_number + 5
  # end

  test "keccak256 hash some data" do
    hash = ExW3.keccak256("foo")
    assert String.slice(hash, 0..1) == "0x"

    assert hash == "0x41b1a0649752af1b28b3dc29a1556eee781e4a4c3a1f7f53f90fa834de098c4d"

    num_bytes =
      hash |>
      String.slice(2..-1) |>
      byte_size

    assert trunc(num_bytes / 2) == 32
  end

  test "starts a Contract GenServer for simple storage contract", context do
    ExW3.Contract.start_link(SimpleStorage, abi: context[:simple_storage_abi])

    {:ok, address, _} =
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

    ExW3.Contract.send(SimpleStorage, :set, [1], %{from: Enum.at(context[:accounts], 0), gas: 50_000})

    {:ok, data} = ExW3.Contract.call(SimpleStorage, :get)

    assert data == 1
  end

  test "starts a Contract GenServer for array tester contract", context do
    ExW3.Contract.start_link(ArrayTester, abi: context[:array_tester_abi])

    {:ok, address, _} =
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

    {:ok, address, _} =
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
            from: Enum.at(context[:accounts], 0),
	    gas: 30_000
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

  test "starts a Contract GenServer and uses the event listener", context do
    ExW3.Contract.start_link(EventTester, abi: context[:event_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        EventTester,
        bin: ExW3.load_bin("test/examples/build/EventTester.bin"),
        options: %{
          gas: 300_000,
          from: Enum.at(context[:accounts], 0)
        }
      )

    ExW3.Contract.at(EventTester, address)

    {:ok, agent} = Agent.start_link(fn -> [] end)
  
    ExW3.EventListener.start_link()

    filter_id = ExW3.Contract.filter(EventTester, "Simple", self())

    {:ok, tx_hash} =
      ExW3.Contract.send(
	EventTester,
	:simple,
	["Hello, World!"],
	%{from: Enum.at(context[:accounts], 0), gas: 30_000}
      )
  
    receive do
      {:event, {filter_id, data}} ->
	Agent.update(agent, fn list -> [data | list] end)	
    after 3_000 ->
	raise "Never received event"
    end

    state = Agent.get(agent, fn list -> list end)
    event_log = Enum.at(state, 0)
    assert event_log |> is_map
    log_data = Map.get(event_log, "data")
    assert log_data |> is_map
    assert Map.get(log_data, "num") == 42
    assert ExW3.bytes_to_string(Map.get(log_data, "data")) == "Hello, World!"

    ExW3.uninstall_filter(filter_id)
  end

  test "starts a Contract GenServer for Complex contract", context do
    ExW3.Contract.start_link(Complex, abi: context[:complex_abi])

    {:ok, address, _} =
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

  test "starts a Contract GenServer for AddressTester contract", context do
    ExW3.Contract.start_link(AddressTester, abi: context[:address_tester_abi])

    {:ok, address, _} =
      ExW3.Contract.deploy(
        AddressTester,
        bin: ExW3.load_bin("test/examples/build/AddressTester.bin"),
        options: %{
          from: Enum.at(context[:accounts], 0),
          gas: 300_000
        }
      )

    ExW3.Contract.at(AddressTester, address)

    assert address == ExW3.Contract.address(AddressTester)

    formatted_address =
			Enum.at(context[:accounts], 0)
			|> ExW3.format_address

    {:ok, same_address} = ExW3.Contract.call(AddressTester, :get, [formatted_address])

    assert ExW3.to_address(same_address) == Enum.at(context[:accounts], 0)
  end

  test "returns checksum for all caps address" do
    assert ExW3.to_checksum_address(String.downcase("0x52908400098527886E0F7030069857D2E4169EE7")) == "0x52908400098527886E0F7030069857D2E4169EE7"
    assert ExW3.to_checksum_address(String.downcase("0x8617E340B3D01FA5F11F306F4090FD50E238070D")) == "0x8617E340B3D01FA5F11F306F4090FD50E238070D"
  end


  test "returns checksumfor all lowercase address" do
    assert ExW3.to_checksum_address(String.downcase("0xde709f2102306220921060314715629080e2fb77")) == "0xde709f2102306220921060314715629080e2fb77"
    assert ExW3.to_checksum_address(String.downcase("0x27b1fdb04752bbc536007a920d24acb045561c26")) == "0x27b1fdb04752bbc536007a920d24acb045561c26"
  end

  test "returns checksum for normal addresses" do
    assert ExW3.to_checksum_address(String.downcase("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed")) == "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
    assert ExW3.to_checksum_address(String.downcase("0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")) == "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"
    assert ExW3.to_checksum_address(String.downcase("0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB")) == "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"
    assert ExW3.to_checksum_address(String.downcase("0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb")) == "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"
  end

  test "returns valid check for is_valid_checksum_address()" do
    assert ExW3.is_valid_checksum_address("0x52908400098527886E0F7030069857D2E4169EE7") == true
    assert ExW3.is_valid_checksum_address("0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB") == true
    assert ExW3.is_valid_checksum_address("0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb") == true
    assert ExW3.is_valid_checksum_address("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed") == true
    assert ExW3.is_valid_checksum_address("0x27b1fdb04752bbc536007a920d24acb045561c26") == true
    assert ExW3.is_valid_checksum_address("0xde709f2102306220921060314715629080e2fb77") == true
    assert ExW3.is_valid_checksum_address("0x8617E340B3D01FA5F11F306F4090FD50E238070D") == true
    assert ExW3.is_valid_checksum_address("0x52908400098527886E0F7030069857D2E4169EE7") == true
  end

  test "returns invalid check for is_valid_checksum_address()" do
    assert ExW3.is_valid_checksum_address("0x2f015c60e0be116b1f0cd534704db9c92118fb6a") == false
  end
end
