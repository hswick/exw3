defmodule ExW3 do

  Module.register_attribute __MODULE__, :unit_map, persist: true, accumulate: false
  
  @unit_map %{
    :noether => 0,
    :wei => 1,
    :kwei => 1_000,
    :Kwei => 1_000,
    :babbage => 1_000,
    :femtoether => 1_000,
    :mwei => 1_000_000,
    :Mwei => 1_000_000,
    :lovelace => 1_000_000,
    :picoether => 1_000_000,
    :gwei => 1_000_000_000,
    :Gwei => 1_000_000_000,
    :shannon => 1_000_000_000,
    :nanoether => 1_000_000_000,
    :nano => 1_000_000_000,
    :szabo => 1_000_000_000_000,
    :microether => 1_000_000_000_000,
    :micro => 1_000_000_000_000,
    :finney => 1_000_000_000_000_000,
    :milliether => 1_000_000_000_000_000,
    :milli => 1_000_000_000_000_000,
    :ether => 1_000_000_000_000_000_000,
    :kether => 1_000_000_000_000_000_000_000,
    :grand => 1_000_000_000_000_000_000_000,
    :mether => 1_000_000_000_000_000_000_000_000,
    :gether => 1_000_000_000_000_000_000_000_000_000,
    :tether => 1_000_000_000_000_000_000_000_000_000_000
  }

  @spec get_unit_map() :: %{}
  @doc "Returns the map used for ether unit conversion"
  def get_unit_map do
    @unit_map
  end

  def to_wei(num, key) do
    if @unit_map[key] do
      num * @unit_map[key]
    else
      throw "#{key} not valid unit"
    end
  end

  def from_wei(num, key) do
    if @unit_map[key] do
      num / @unit_map[key]
    else
      throw "#{key} not valid unit"
    end
  end

  @spec keccak256(binary()) :: binary()
  @doc "Returns a 0x prepended 32 byte hash of the input string"
  def keccak256(string) do
    Enum.join(["0x", ExthCrypto.Hash.Keccak.kec(string) |> Base.encode16(case: :lower)], "")
  end
  
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

    hash = ExthCrypto.Hash.Keccak.kec(String.downcase(address))
           |> Base.encode16(case: :lower)
           |> String.replace(~r/^0x/, "")

    keccak_hash_list = hash
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

  @spec new_filter(%{}) :: binary()
  @doc "Creates a new filter, returns filter id"
  def new_filter(map) do
    case Ethereumex.HttpClient.eth_new_filter(map) do
      {:ok, filter_id} -> filter_id
      err -> err
    end
  end

  def get_filter_changes(filter_id) do
    case Ethereumex.HttpClient.eth_get_filter_changes(filter_id) do
      {:ok, changes} -> changes
      err -> err
    end
  end

  @spec uninstall_filter(binary()) :: boolean()
  def uninstall_filter(filter_id) do
    case Ethereumex.HttpClient.eth_uninstall_filter(filter_id) do
      {:ok, result} -> result
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

    abi
    |> Enum.map(&map_abi/1)
    |> Map.new

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


  @spec encode_option(integer()) :: binary()
  @doc "Encodes options into Ethereum JSON RPC hex string"
  def encode_option(0), do: "0x0"

  def encode_option(value) do
    "0x" <> (value |> :binary.encode_unsigned() |> Base.encode16(case: :lower) |> String.trim_leading("0"))
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

  # ABI mapper

  defp map_abi(x) do
    case {x["name"], x["type"]} do
      {nil, "constructor"} -> {:constructor, x}
      {nil, "fallback"} -> {:fallback, x}
      {name, _} -> {name, x}
    end
  end

  defmodule Poller do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, [], name: EventPoller)
    end

    def filter(filter_id) do
      GenServer.cast(EventPoller, {:filter, filter_id})
    end

    @impl true
    def init(state) do
      schedule_work() # Schedule work to be performed on start
      {:ok, state}
    end

    @impl true
    def handle_cast({:filter, filter_id}, state) do
      {:noreply, [filter_id | state]}
    end

    @impl true
    def handle_info(:work, state) do
      # Do the desired work here
      Enum.each state, fn filter_id ->
	send Listener, {:event, filter_id, ExW3.get_filter_changes(filter_id)}
      end
      
      schedule_work() # Reschedule once more
      {:noreply, state}
    end

    defp schedule_work() do
      Process.send_after(self(), :work, 500) # In 1/2 sec
    end
  end
  
  defmodule EventListener do
    def start_link do
      Poller.start_link()
      {:ok, pid} = Task.start_link(fn -> loop(%{}) end)
      Process.register(pid, Listener)
      :ok
    end

    def filter(filter_id, event_signature, event_fields, pid) do
      Poller.filter(filter_id)
      send Listener, {:filter, filter_id, event_signature, event_fields, pid}
    end

    def listen(callback) do
      receive do
	{:event, result} -> apply callback, [result]
      end
      listen(callback)
    end
    
    defp loop(state) do
      receive do
	{:filter, filter_id, event_signature, event_fields, pid} ->
	  loop(Map.put(state, filter_id, %{pid: pid, signature: event_signature, names: event_fields}))
	{:event, filter_id, logs} ->
	  filter_attributes = Map.get(state, filter_id)
	  unless logs == [] do
	    Enum.each(logs, fn log ->
	      data = Map.get(log, "data")
	      new_data = Enum.zip(filter_attributes[:names], ExW3.decode_event(data, filter_attributes[:signature])) |> Enum.into(%{})
	      new_log = Map.put(log, "data", new_data)
	      send filter_attributes[:pid], {:event, {filter_id, new_log}}
	    end)
	  end
	  loop(state)
      end
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

    def filter(pid, event_name, other_pid, event_data \\ %{}) do
      GenServer.call(pid, {:filter, {event_name, other_pid, event_data}})
    end

    # Server

    def init(state) do
      if state[:abi] do
	{:ok, state ++ init_events(state[:abi])}
      else
        raise "ABI not provided upon initialization"
      end
    end

    defp init_events(abi) do
      events =
        Enum.filter(abi, fn {_, v} ->
          v["type"] == "event"
        end)

      names_and_signature_types_map =
        Enum.map(events, fn {name, v} ->
          types = Enum.map(v["inputs"], &Map.get(&1, "type"))
          names = Enum.map(v["inputs"], &Map.get(&1, "name"))
          signature = Enum.join([name, "(", Enum.join(types, ","), ")"])

	  encoded_event_signature = "0x#{ExW3.encode_event(signature)}"

          {{encoded_event_signature, %{signature: signature, names: names}}, {name, encoded_event_signature}}
        end)

      signature_types_map =
	Enum.map(names_and_signature_types_map, fn {signature_types, _} ->
	  signature_types
	end)

      names_map =
	Enum.map(names_and_signature_types_map, fn {_, names} ->
	  names
	end)

      [events: Enum.into(signature_types_map, %{}), event_names: Enum.into(names_map, %{})]
    end

    # Helpers

    def deploy_helper(bin, abi, args) do
      constructor_arg_data =
        if arguments = args[:args] do
          constructor_abi =
            Enum.find(abi, fn {_, v} ->
              v["type"] == "constructor"
            end)

          if constructor_abi do
            {_, constructor} = constructor_abi
            input_types = Enum.map(constructor["inputs"], fn x -> x["type"] end)
            types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])

            if Enum.count(input_types) != Enum.count(arguments) do
                throw "Number of provided arguments is invalid"
            end

            bin <> (ExW3.encode_data(types_signature, arguments) |> Base.encode16(case: :lower))
          else
            #IO.warn("Could not find a constructor")
            bin
          end
        else
          bin
        end

      gas = ExW3.encode_option(args[:options][:gas])

      tx = %{
        from: args[:options][:from],
        data: "0x#{constructor_arg_data}",
        gas: gas
      }

      {:ok, tx_hash} = Ethereumex.HttpClient.eth_send_transaction(tx)

      {:ok, tx_receipt} = Ethereumex.HttpClient.eth_get_transaction_receipt(tx_hash)

      {tx_receipt["contractAddress"], tx_hash}
    end

    def eth_call_helper(address, abi, method_name, args) do
      result =
        Ethereumex.HttpClient.eth_call(%{
          to: address,
          data: "0x#{ExW3.encode_method_call(abi, method_name, args)}"
        })

      case result do
        {:ok, data} -> ([:ok] ++ ExW3.decode_output(abi, method_name, data)) |> List.to_tuple()
        {:error, err} -> {:error, err}
      end
    end

    def eth_send_helper(address, abi, method_name, args, options) do
      gas = ExW3.encode_option(options[:gas])
      Ethereumex.HttpClient.eth_send_transaction(
        Map.merge(
          %{
            to: address,
            data: "0x#{ExW3.encode_method_call(abi, method_name, args)}"
          },
          Map.put(options, :gas, gas)
        )
      )
    end


    # Options' checkers

    defp check_option(nil, error_atom), do: {:error, error_atom}
    defp check_option([], error_atom), do: {:error, error_atom}
    defp check_option([head | _tail], _atom) when head != nil,  do: {:ok, head}
    defp check_option([_head | tail], atom), do: check_option(tail, atom)
    defp check_option(value, _atom), do: {:ok, value}

    # Casts

    def handle_cast({:at, address}, state) do
      {:noreply, [{:address, address} | state]}
    end

    def handle_call({:filter, {event_name, other_pid, event_data}}, _from, state) do
      unless Process.whereis(Listener) do
	raise "EventListener process not alive. Call ExW3.EventListener.start_link before using ExW3.Contract.subscribe"
      end
      payload = Map.merge(%{address: state[:address], topics: [state[:event_names][event_name]]}, event_data)
      filter_id = ExW3.new_filter(payload)
      event_signature = state[:events][state[:event_names][event_name]][:signature]
      event_fields = state[:events][state[:event_names][event_name]][:names]
      EventListener.filter(filter_id, event_signature, event_fields, other_pid)
      {:reply, filter_id, state ++ [event_name, filter_id]}
    end

    # Calls

    def handle_call({:deploy, args}, _from, state) do
      with {:ok, _} <- check_option(args[:options][:from], :missing_sender),
           {:ok,_} <- check_option(args[:options][:gas], :missing_gas),
           {:ok, bin} <- check_option([state[:bin], args[:bin]], :missing_binary)
       do
        {contract_addr, tx_hash} = deploy_helper(bin, state[:abi], args)
        result = {:ok, contract_addr, tx_hash}
        {:reply, result , state}
       else
         err -> {:reply, err, state}
       end
    end

    def handle_call(:address, _from, state) do
      {:reply, state[:address], state}
    end

    def handle_call({:call, {method_name, args}}, _from, state) do
      with {:ok, address} <- check_option(state[:address], :missing_address)
        do
          result = eth_call_helper(address, state[:abi], Atom.to_string(method_name), args)
         {:reply, result, state}
        else
         err -> {:reply, err, state}
      end
    end

    def handle_call({:send, {method_name, args, options}}, _from, state) do
      with {:ok, address} <- check_option(state[:address], :missing_address),
           {:ok, _} <- check_option(options[:from], :missing_sender),
           {:ok, _} <- check_option(options[:gas], :missing_gas)
        do
          result = eth_send_helper(address, state[:abi], Atom.to_string(method_name), args, options)
          {:reply, result, state}
        else
          err -> {:reply, err, state}
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
