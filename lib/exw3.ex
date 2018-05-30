defmodule ExW3 do
  @spec bytes_to_string(binary()) :: binary()
  @doc "converts Ethereum style bytes to string"
  def bytes_to_string(bytes) do
    bytes
    |> Base.encode16(case: :lower)
    |> String.replace_trailing("0", "")
    |> Base.decode16!(case: :lower)
  end

  @spec format_address(binary()) :: integer()
  @doc "Converts an Ethereum address into a form that can be used by the ABI encoder"
  def format_address(address) do
    address
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> :binary.decode_unsigned
  end

  @spec to_address(binary()) :: binary()
  @doc "Converts bytes to Ethereum address"
  def to_address(bytes) do
    Enum.join(["0x", bytes |> Base.encode16(case: :lower)], "")
  end

	@spec to_checksum_address(binary()) :: binary()
	@doc "returns a checksummed address"
	def to_checksum_address(address) do
    address = String.replace(address, ~r/^0x/, "")

    {:ok, hash} = Ethereumex.HttpClient.web3_sha3(String.downcase(address))
    non_prefix_hash = String.replace(hash, ~r/^0x/, "")
    keccak_hash_list = non_prefix_hash
    |> String.split("", trim: true)
    |> Enum.map(fn (x) -> elem(Integer.parse(x, 16),0) end)

    list_arr = for n <- 0..String.length(address)-1 do
      number = Enum.at(keccak_hash_list, n)
      cond do
        number >= 8 -> String.upcase(String.at(address, n))
        true -> String.downcase(String.at(address, n))
      end
    end

    "0x" <> List.to_string(list_arr)
  end
	
	@doc "checks if the address is a valid checksummed address"
	@spec is_valid_checksum_address(binary()) :: boolean()
  def is_valid_checksum_address(address) do
    to_checksum_address(address) == address
  end

  @spec accounts() :: list()
  @doc "returns all available accounts"
  def accounts do
    case Ethereumex.HttpClient.eth_accounts() do
      {:ok, accounts} -> accounts
      err -> err
    end
  end

  @spec to_decimal(binary()) :: number()
  @doc "Converts ethereum hex string to decimal number"
  def to_decimal(hex_string) do
    hex_string
    |> String.slice(2..-1)
    |> String.to_integer(16)
  end

  @spec block_number() :: integer()
  @doc "Returns the current block number"
  def block_number do
    case Ethereumex.HttpClient.eth_block_number() do
      {:ok, block_number} ->
        block_number |> to_decimal

      err ->
        err
    end
  end

  @spec balance(binary()) :: integer()
  @doc "Returns current balance of account"
  def balance(account) do
    case Ethereumex.HttpClient.eth_get_balance(account) do
      {:ok, balance} ->
        balance |> to_decimal

      err ->
        err
    end
  end

  @spec keys_to_decimal(%{}, []) :: %{}
  def keys_to_decimal(map, keys) do
    Map.new(
      Enum.map(keys, fn k ->
        {k, Map.get(map, k) |> to_decimal}
      end)
    )
  end

  @spec tx_receipt(binary()) :: %{}
  @doc "Returns transaction receipt for specified transaction hash(id)"
  def tx_receipt(tx_hash) do
    case Ethereumex.HttpClient.eth_get_transaction_receipt(tx_hash) do
      {:ok, receipt} ->
        Map.merge(
          receipt,
          keys_to_decimal(receipt, ["blockNumber", "cumulativeGasUsed", "gasUsed"])
        )

      err ->
        err
    end
  end

  @spec block(integer()) :: any()
  @doc "Returns block data for specified block number"
  def block(block_number) do
    case Ethereumex.HttpClient.eth_get_block_by_number(block_number, true) do
      {:ok, block} -> block
      err -> err
    end
  end

  @spec mine(integer()) :: any()
  @doc "Mines number of blocks specified. Default is 1"
  def mine(num_blocks \\ 1) do
    for _ <- 0..(num_blocks - 1) do
      Ethereumex.HttpClient.request("evm_mine", [], [])
    end
  end

  @spec encode_event(binary()) :: binary()
  @doc "Encodes event based on signature"
  def encode_event(signature) do
    ExthCrypto.Hash.Keccak.kec(signature) |> Base.encode16(case: :lower)
  end

  @spec decode_event(binary(), binary()) :: any()
  @doc "Decodes event based on given data and provided signature"
  def decode_event(data, signature) do
    formatted_data =
      data
      |> String.slice(2..-1)
      |> Base.decode16!(case: :lower)

    fs = ABI.FunctionSelector.decode(signature)

    ABI.TypeDecoder.decode(formatted_data, fs)
  end

  @spec reformat_abi([]) :: %{}
  @doc "Reformats abi from list to map with event and function names as keys"
  def reformat_abi(abi) do
    Map.new(Enum.map(abi, fn x -> {x["name"], x} end))
  end

  @spec load_abi(binary()) :: []
  @doc "Loads the abi at the file path and reformats it to a map"
  def load_abi(file_path) do
    file = File.read(Path.join(System.cwd(), file_path))

    case file do
      {:ok, abi} -> reformat_abi(Poison.Parser.parse!(abi))
      err -> err
    end
  end

  @spec load_bin(binary()) :: binary()
  @doc "Loads the bin ar the file path"
  def load_bin(file_path) do
    file = File.read(Path.join(System.cwd(), file_path))

    case file do
      {:ok, bin} -> bin
      err -> err
    end
  end

  @spec decode_output(%{}, binary(), binary()) :: []
  @doc "Decodes output based on specified functions return signature"
  def decode_output(abi, name, output) do
    {:ok, trim_output} =
      String.slice(output, 2..String.length(output)) |> Base.decode16(case: :lower)

    output_types = Enum.map(abi[name]["outputs"], fn x -> x["type"] end)
    types_signature = Enum.join(["(", Enum.join(output_types, ","), ")"])
    output_signature = "#{name}(#{types_signature})"

    outputs =
      ABI.decode(output_signature, trim_output)
      |> List.first()
      |> Tuple.to_list()

    outputs
  end

  @spec types_signature(%{}, binary()) :: binary()
  @doc "Returns the type signature of a given function"
  def types_signature(abi, name) do
    input_types = Enum.map(abi[name]["inputs"], fn x -> x["type"] end)
    types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])
    types_signature
  end

  @spec method_signature(%{}, binary()) :: binary()
  @doc "Returns the 4 character method id based on the hash of the method signature"
  def method_signature(abi, name) do
    if abi[name] do
      input_signature = "#{name}#{types_signature(abi, name)}" |> ExthCrypto.Hash.Keccak.kec()

      # Take first four bytes
      <<init::binary-size(4), _rest::binary>> = input_signature
      init
    else
      raise "#{name} method not found in the given abi"
    end
  end

  @spec encode_data(binary(), []) :: binary()
  @doc "Encodes data into Ethereum hex string based on types signature"
  def encode_data(types_signature, data) do
    ABI.TypeEncoder.encode_raw(
      [List.to_tuple(data)],
      ABI.FunctionSelector.decode_raw(types_signature)
    )
  end

  @spec encode_method_call(%{}, binary(), []) :: binary()
  @doc "Encodes data and appends it to the encoded method id"
  def encode_method_call(abi, name, input) do
    encoded_method_call =
      method_signature(abi, name) <> encode_data(types_signature(abi, name), input)

    encoded_method_call |> Base.encode16(case: :lower)
  end

  @spec encode_input(%{}, binary(), []) :: binary()
  @doc "Encodes input from a method call based on function signature"
  def encode_input(abi, name, input) do
    if abi[name]["inputs"] do
      input_types = Enum.map(abi[name]["inputs"], fn x -> x["type"] end)
      types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])
      input_signature = "#{name}#{types_signature}" |> ExthCrypto.Hash.Keccak.kec()

      # Take first four bytes
      <<init::binary-size(4), _rest::binary>> = input_signature

      encoded_input =
        init <>
          ABI.TypeEncoder.encode_raw(
            [List.to_tuple(input)],
            ABI.FunctionSelector.decode_raw(types_signature)
          )

      encoded_input |> Base.encode16(case: :lower)
    else
      raise "#{name} method not found with the given abi"
    end
  end

  defmodule Contract do
    use GenServer

    # Client

    @spec start_link(atom(), list()) :: {:ok, pid()}
    @doc "Begins a Contract GenServer with specified name and state"
    def start_link(name, state) do
      GenServer.start_link(__MODULE__, state, name: name)
    end

    @spec deploy(pid(), []) :: {:ok, []}
    @doc "Deploys contracts with given arguments"
    def deploy(pid, args) do
      GenServer.call(pid, {:deploy, args})
    end

    @spec at(pid(), binary()) :: :ok
    @doc "Sets the current Contract GenServer's address to given address"
    def at(pid, address) do
      GenServer.cast(pid, {:at, address})
    end

    @spec address(pid()) :: {:ok, binary()}
    @doc "Returns the current Contract GenServer's address"
    def address(pid) do
      GenServer.call(pid, :address)
    end

    @spec call(pid(), keyword(), []) :: {:ok, any()}
    @doc "Use a Contract's method with an eth_call"
    def call(pid, method_name, args \\ []) do
      GenServer.call(pid, {:call, {method_name, args}})
    end

    @spec send(pid(), keyword(), [], %{}) :: {:ok, binary()}
    @doc "Use a Contract's method with an eth_sendTransaction"
    def send(pid, method_name, args, options) do
      GenServer.call(pid, {:send, {method_name, args, options}})
    end

    @spec tx_receipt(pid(), binary()) :: %{}
    @doc "Returns a formatted transaction receipt for the given transaction hash(id)"
    def tx_receipt(pid, tx_hash) do
      GenServer.call(pid, {:tx_receipt, tx_hash})
    end

    # Server

    def init(state) do
      if state[:abi] do
        {:ok, [{:events, init_events(state[:abi])} | state]}
      else
        raise "ABI not provided upon initialization"
      end
    end

    defp init_events(abi) do
      events =
        Enum.filter(abi, fn {_, v} ->
          v["type"] == "event"
        end)

      signature_types_map =
        Enum.map(events, fn {name, v} ->
          types = Enum.map(v["inputs"], &Map.get(&1, "type"))
          names = Enum.map(v["inputs"], &Map.get(&1, "name"))
          signature = Enum.join([name, "(", Enum.join(types, ","), ")"])

          {"0x#{ExW3.encode_event(signature)}", %{signature: signature, names: names}}
        end)

      Enum.into(signature_types_map, %{})
    end

    # Helpers

    def deploy_helper(bin, abi, args) do
      constructor_arg_data =
        if args[:args] do
          constructor_abi =
            Enum.find(abi, fn {_, v} ->
              v["type"] == "constructor"
            end)

          if constructor_abi do
            {_, constructor} = constructor_abi
            input_types = Enum.map(constructor["inputs"], fn x -> x["type"] end)
            types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])
            bin <> (ExW3.encode_data(types_signature, args[:args]) |> Base.encode16(case: :lower))
          else
            bin
          end
        else
          bin
        end

      tx = %{
        from: args[:options][:from],
        data: constructor_arg_data,
        gas: args[:options][:gas]
      }

      {:ok, tx_receipt_id} = Ethereumex.HttpClient.eth_send_transaction(tx)

      {:ok, tx_receipt} = Ethereumex.HttpClient.eth_get_transaction_receipt(tx_receipt_id)

      tx_receipt["contractAddress"]
    end

    def eth_call_helper(address, abi, method_name, args) do
      result =
        Ethereumex.HttpClient.eth_call(%{
          to: address,
          data: ExW3.encode_method_call(abi, method_name, args)
        })

      case result do
        {:ok, data} -> ([:ok] ++ ExW3.decode_output(abi, method_name, data)) |> List.to_tuple()
        {:error, err} -> {:error, err}
      end
    end

    def eth_send_helper(address, abi, method_name, args, options) do
      Ethereumex.HttpClient.eth_send_transaction(
        Map.merge(
          %{
            to: address,
            data: ExW3.encode_method_call(abi, method_name, args)
          },
          options
        )
      )
    end

    # Casts

    def handle_cast({:at, address}, state) do
      {:noreply, [{:address, address} | state]}
    end

    # Calls

    def handle_call({:deploy, args}, _from, state) do
      case {args[:bin], state[:bin]} do
        {nil, nil} -> {:reply, {:error, "contract binary was never provided"}, state}
        {bin, nil} -> {:reply, {:ok, deploy_helper(bin, state[:abi], args)}, state}
        {nil, bin} -> {:reply, {:ok, deploy_helper(bin, state[:abi], args)}, state}
      end
    end

    def handle_call(:address, _from, state) do
      {:reply, state[:address], state}
    end

    def handle_call({:call, {method_name, args}}, _from, state) do
      address = state[:address]

      if address do
        result = eth_call_helper(address, state[:abi], Atom.to_string(method_name), args)
        {:reply, result, state}
      else
        {:reply, {:error, "contract address not available"}, state}
      end
    end

    def handle_call({:send, {method_name, args, options}}, _from, state) do
      address = state[:address]

      if address do
        result = eth_send_helper(address, state[:abi], Atom.to_string(method_name), args, options)
        {:reply, result, state}
      else
        {:reply, {:error, "contract address not available"}, state}
      end
    end

    def handle_call({:tx_receipt, tx_hash}, _from, state) do
      receipt = ExW3.tx_receipt(tx_hash)
      events = state[:events]
      logs = receipt["logs"]

      formatted_logs =
        Enum.map(logs, fn log ->
          topic = Enum.at(log["topics"], 0)
          event = Map.get(events, topic)

          if event do
            Enum.zip(event[:names], ExW3.decode_event(log["data"], event[:signature]))
            |> Enum.into(%{})
          else
            nil
          end
        end)

      {:reply, {:ok, {receipt, formatted_logs}}, state}
    end
  end
end
