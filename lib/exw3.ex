defmodule ExW3 do
  Module.register_attribute(__MODULE__, :unit_map, persist: true, accumulate: false)
  Module.register_attribute(__MODULE__, :client_type, persist: true, accumulate: false)

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

  @spec get_client_type() :: atom()
  def get_client_type do
    Application.get_env(:ethereumex, :client_type, :http)
  end

  @spec get_unit_map() :: map()
  @doc "Returns the map used for ether unit conversion"
  def get_unit_map do
    @unit_map
  end

  @spec to_wei(integer(), atom()) :: integer()
  @doc "Converts the value to whatever unit key is provided. See unit map for details."
  def to_wei(num, key) do
    if @unit_map[key] do
      num * @unit_map[key]
    else
      throw("#{key} not valid unit")
    end
  end

  @spec from_wei(integer(), atom()) :: integer() | float() | no_return
  @doc "Converts the value to whatever unit key is provided. See unit map for details."
  def from_wei(num, key) do
    if @unit_map[key] do
      num / @unit_map[key]
    else
      throw("#{key} not valid unit")
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
    |> :binary.decode_unsigned()
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

    hash =
      ExthCrypto.Hash.Keccak.kec(String.downcase(address))
      |> Base.encode16(case: :lower)
      |> String.replace(~r/^0x/, "")

    keccak_hash_list =
      hash
      |> String.split("", trim: true)
      |> Enum.map(fn x -> elem(Integer.parse(x, 16), 0) end)

    list_arr =
      for n <- 0..(String.length(address) - 1) do
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

  defp call_client(method_name, arguments \\ []) do
    case get_client_type() do
      :http -> apply(Ethereumex.HttpClient, method_name, arguments)
      :ipc -> apply(Ethereumex.IpcClient, method_name, arguments)
      _ -> {:error, :invalid_client_type}
    end
  end

  @spec accounts() :: list()
  @doc "returns all available accounts"
  def accounts do
    case call_client(:eth_accounts) do
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
    case call_client(:eth_block_number) do
      {:ok, block_number} ->
        block_number |> to_decimal

      err ->
        err
    end
  end

  @spec balance(binary()) :: integer() | {:error, any()}
  @doc "Returns current balance of account"
  def balance(account) do
    case call_client(:eth_get_balance, [account]) do
      {:ok, balance} ->
        balance |> to_decimal

      err ->
        err
    end
  end

  @spec keys_to_decimal(map(), list()) :: map()
  def keys_to_decimal(map, keys) do
    for k <- keys, into: %{}, do: {k, map |> Map.get(k) |> to_decimal()}
  end

  @spec tx_receipt(binary()) :: {:ok, map()} | {:error, any()}
  @doc "Returns transaction receipt for specified transaction hash(id)"
  def tx_receipt(tx_hash) do
    case call_client(:eth_get_transaction_receipt, [tx_hash]) do
      {:ok, nil} ->
        {:error, :not_mined}

      {:ok, receipt} ->
        decimal_res = keys_to_decimal(receipt, ~w(blockNumber cumulativeGasUsed gasUsed))

        {:ok, Map.merge(receipt, decimal_res)}

      err ->
        {:error, err}
    end
  end

  @spec block(integer()) :: any() | {:error, any()}
  @doc "Returns block data for specified block number"
  def block(block_number) do
    case call_client(:eth_get_block_by_number, [block_number, true]) do
      {:ok, block} -> block
      err -> err
    end
  end

  @spec new_filter(map()) :: binary() | {:error, any()}
  @doc "Creates a new filter, returns filter id. For more sophisticated use, prefer ExW3.Contract.filter."
  def new_filter(map) do
    case call_client(:eth_new_filter, [map]) do
      {:ok, filter_id} -> filter_id
      err -> err
    end
  end

  @spec get_filter_changes(binary()) :: any()
  @doc "Gets event changes (logs) by filter. Unlike ExW3.Contract.get_filter_changes it does not return the data in a formatted way"
  def get_filter_changes(filter_id) do
    case call_client(:eth_get_filter_changes, [filter_id]) do
      {:ok, changes} -> changes
      err -> err
    end
  end

  @spec uninstall_filter(binary()) :: boolean() | {:error, any()}
  @doc "Uninstalls filter from the ethereum node"
  def uninstall_filter(filter_id) do
    case call_client(:eth_uninstall_filter, [filter_id]) do
      {:ok, result} -> result
      err -> err
    end
  end

  @spec mine(integer()) :: any() | {:error, any()}
  @doc "Mines number of blocks specified. Default is 1"
  def mine(num_blocks \\ 1) do
    for _ <- 0..(num_blocks - 1) do
      call_client(:request, ["evm_mine", [], []])
    end
  end

  @spec personal_list_accounts(list()) :: {:ok, list()} | {:error, any()}
  @doc "Using the personal api, returns list of accounts."
  def personal_list_accounts(opts \\ []) do
    call_client(:request, ["personal_listAccounts", [], opts])
  end

  @spec personal_new_account(binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method creates a new account with the passphrase, and returns new account address."
  def personal_new_account(password, opts \\ []) do
    call_client(:request, ["personal_newAccount", [password], opts])
  end

  @spec personal_unlock_account(binary(), list()) :: {:ok, boolean()} | {:error, any()}
  @doc "Using the personal api, this method unlocks account using the passphrase provided, and returns a boolean."
  def personal_unlock_account(password, opts) do
    call_client(:request, ["personal_unlockAccount", [password], opts])
  end

  @spec personal_send_transaction(map(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method sends a transaction and signs it in one call, and returns a transaction id hash."
  def personal_send_transaction(param_map, passphrase, opts \\ []) do
    call_client(:request, ["personal_sendTransaction", [param_map, passphrase], opts])
  end

  @spec personal_sign_transaction(map(), binary(), list()) :: {:ok, map()} | {:error, any()}
  @doc "Using the personal api, this method signs a transaction, and returns the signed transaction."
  def personal_sign_transaction(param_map, passphrase, opts \\ []) do
    call_client(:request, ["personal_signTransaction", [param_map, passphrase], opts])
  end

  @spec personal_sign(binary(), binary(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method calculates an Ethereum specific signature, and returns that signature."
  def personal_sign(data, address, passphrase, opts \\ []) do
    call_client(:request, ["personal_sign", [data, address, passphrase], opts])
  end

  @spec personal_ec_recover(binary(), binary(), []) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method returns the address associated with the private key that was used to calculate the signature with personal_sign."
  def personal_ec_recover(data0, data1, opts \\ []) do
    call_client(:request, ["personal_ecRecover", [data0, data1], opts])
  end

  @spec eth_sign(binary(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Calculates an Ethereum specific signature and signs the data provided, using the accounts private key"
  def eth_sign(data0, data1, opts \\ []) do
    call_client(:request, ["eth_sign", [data0, data1], opts])
  end

  @spec encode_event(binary()) :: binary()
  @doc "Encodes event based on signature"
  def encode_event(signature) do
    ExthCrypto.Hash.Keccak.kec(signature) |> Base.encode16(case: :lower)
  end

  @spec eth_call(list()) :: any()
  @doc "Simple eth_call to client. Recommended to use ExW3.Contract.call instead."
  def eth_call(arguments) do
    call_client(:eth_call, arguments)
  end

  @spec eth_send(list()) :: any()
  @doc "Simple eth_send_transaction. Recommended to use ExW3.Contract.send instead."
  def eth_send(arguments) do
    call_client(:eth_send_transaction, arguments)
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

  @spec reformat_abi(list()) :: map()
  @doc "Reformats abi from list to map with event and function names as keys"
  def reformat_abi(abi) do
    abi
    |> Enum.map(&map_abi/1)
    |> Map.new()
  end

  @spec load_abi(binary()) :: list() | {:error, atom()}
  @doc "Loads the abi at the file path and reformats it to a map"
  def load_abi(file_path) do
    file = File.read(Path.join(System.cwd(), file_path))

    case file do
      {:ok, abi} -> reformat_abi(Poison.Parser.parse!(abi, %{}))
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

  @spec decode_data(binary(), binary()) :: any()
  @doc "Decodes data based on given type signature"
  def decode_data(types_signature, data) do
    {:ok, trim_data} = String.slice(data, 2..String.length(data)) |> Base.decode16(case: :lower)

    ABI.decode(types_signature, trim_data) |> List.first()
  end

  @spec decode_output(map(), binary(), binary()) :: list()
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

  @spec types_signature(map(), binary()) :: binary()
  @doc "Returns the type signature of a given function"
  def types_signature(abi, name) do
    input_types = Enum.map(abi[name]["inputs"], fn x -> x["type"] end)
    types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])
    types_signature
  end

  @spec method_signature(map(), binary()) :: binary()
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

  @spec encode_data(binary(), list()) :: binary()
  @doc "Encodes data into Ethereum hex string based on types signature"
  def encode_data(types_signature, data) do
    ABI.TypeEncoder.encode_raw(
      [List.to_tuple(data)],
      ABI.FunctionSelector.decode_raw(types_signature)
    )
  end

  @spec encode_options(map(), list()) :: map()
  @doc "Encodes list of options and returns them as a map"
  def encode_options(options, keys) do
    keys
    |> Enum.filter(fn option ->
      Map.has_key?(options, option)
    end)
    |> Enum.map(fn option ->
      {option, encode_option(options[option])}
    end)
    |> Enum.into(%{})
  end

  @spec encode_option(integer()) :: binary()
  @doc "Encodes options into Ethereum JSON RPC hex string"
  def encode_option(0), do: "0x0"

  def encode_option(nil), do: nil

  def encode_option(value) do
    "0x" <>
      (value
       |> :binary.encode_unsigned()
       |> Base.encode16(case: :lower)
       |> String.trim_leading("0"))
  end

  @spec encode_method_call(map(), binary(), list()) :: binary()
  @doc "Encodes data and appends it to the encoded method id"
  def encode_method_call(abi, name, input) do
    encoded_method_call =
      method_signature(abi, name) <> encode_data(types_signature(abi, name), input)

    encoded_method_call |> Base.encode16(case: :lower)
  end

  @spec encode_input(map(), binary(), list()) :: binary()
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

  defmodule Contract do
    use GenServer

    # Client

    @spec start_link() :: {:ok, pid()}
    @doc "Begins the Contract process to manage all interactions with smart contracts"
    def start_link() do
      GenServer.start_link(__MODULE__, %{filters: %{}}, name: ContractManager)
    end

    @spec deploy(atom(), list()) :: {:ok, binary(), binary()}
    @doc "Deploys contracts with given arguments"
    def deploy(name, args) do
      GenServer.call(ContractManager, {:deploy, {name, args}})
    end

    @spec register(atom(), list()) :: :ok
    @doc "Registers the contract with the ContractManager process. Only :abi is required field."
    def register(name, contract_info) do
      GenServer.cast(ContractManager, {:register, {name, contract_info}})
    end

    @spec uninstall_filter(binary()) :: :ok
    @doc "Uninstalls the filter, and deletes the data associated with the filter id"
    def uninstall_filter(filter_id) do
      GenServer.cast(ContractManager, {:uninstall_filter, filter_id})
    end

    @spec at(atom(), binary()) :: :ok
    @doc "Sets the address for the contract specified by the name argument"
    def at(name, address) do
      GenServer.cast(ContractManager, {:at, {name, address}})
    end

    @spec address(atom()) :: {:ok, binary()}
    @doc "Returns the current Contract GenServer's address"
    def address(name) do
      GenServer.call(ContractManager, {:address, name})
    end

    @spec call(atom(), atom(), list()) :: {:ok, any()}
    @doc "Use a Contract's method with an eth_call"
    def call(contract_name, method_name, args \\ []) do
      GenServer.call(ContractManager, {:call, {contract_name, method_name, args}})
    end

    @spec send(atom(), atom(), list(), map()) :: {:ok, binary()}
    @doc "Use a Contract's method with an eth_sendTransaction"
    def send(contract_name, method_name, args, options) do
      GenServer.call(ContractManager, {:send, {contract_name, method_name, args, options}})
    end

    @spec tx_receipt(atom(), binary()) :: map()
    @doc "Returns a formatted transaction receipt for the given transaction hash(id)"
    def tx_receipt(contract_name, tx_hash) do
      GenServer.call(ContractManager, {:tx_receipt, {contract_name, tx_hash}})
    end

    @spec filter(atom(), binary(), map()) :: {:ok, binary()}
    @doc "Installs a filter on the Ethereum node. This also formats the parameters, and saves relevant information to format event logs."
    def filter(contract_name, event_name, event_data \\ %{}) do
      GenServer.call(
        ContractManager,
        {:filter, {contract_name, event_name, event_data}}
      )
    end

    @spec get_filter_changes(binary()) :: {:ok, list()}
    @doc "Using saved information related to the filter id, event logs are formatted properly"
    def get_filter_changes(filter_id) do
      GenServer.call(
        ContractManager,
        {:get_filter_changes, filter_id}
      )
    end

    # Server

    def init(state) do
      {:ok, state}
    end

    defp data_signature_helper(name, fields) do
      non_indexed_types = Enum.map(fields, &Map.get(&1, "type"))
      Enum.join([name, "(", Enum.join(non_indexed_types, ","), ")"])
    end

    defp topic_types_helper(fields) do
      if length(fields) > 0 do
        Enum.map(fields, fn field ->
          "(#{field["type"]})"
        end)
      else
        []
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
          signature = Enum.join([name, "(", Enum.join(types, ","), ")"])

          encoded_event_signature = "0x#{ExW3.encode_event(signature)}"

          indexed_fields =
            Enum.filter(v["inputs"], fn input ->
              input["indexed"]
            end)

          indexed_names =
            Enum.map(indexed_fields, fn field ->
              field["name"]
            end)

          non_indexed_fields =
            Enum.filter(v["inputs"], fn input ->
              !input["indexed"]
            end)

          non_indexed_names =
            Enum.map(non_indexed_fields, fn field ->
              field["name"]
            end)

          data_signature = data_signature_helper(name, non_indexed_fields)

          event_attributes = %{
            signature: data_signature,
            non_indexed_names: non_indexed_names,
            topic_types: topic_types_helper(indexed_fields),
            topic_names: indexed_names
          }

          {{encoded_event_signature, event_attributes}, {name, encoded_event_signature}}
        end)

      signature_types_map =
        Enum.map(names_and_signature_types_map, fn {signature_types, _} ->
          signature_types
        end)

      names_map =
        Enum.map(names_and_signature_types_map, fn {_, names} ->
          names
        end)

      [
        events: Enum.into(signature_types_map, %{}),
        event_names: Enum.into(names_map, %{})
      ]
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

            arg_count = Enum.count(arguments)
            input_types_count = Enum.count(input_types)

            if input_types_count != arg_count do
              raise "Number of provided arguments to constructor is incorrect. Was given #{
                      arg_count
                    } args, looking for #{input_types_count}."
            end

            bin <> (ExW3.encode_data(types_signature, arguments) |> Base.encode16(case: :lower))
          else
            # IO.warn("Could not find a constructor")
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

      {:ok, tx_hash} = ExW3.eth_send([tx])

      {:ok, tx_receipt} = ExW3.tx_receipt(tx_hash)

      {tx_receipt["contractAddress"], tx_hash}
    end

    def eth_call_helper(address, abi, method_name, args) do
      result =
        ExW3.eth_call([
          %{
            to: address,
            data: "0x#{ExW3.encode_method_call(abi, method_name, args)}"
          }
        ])

      case result do
        {:ok, data} -> ([:ok] ++ ExW3.decode_output(abi, method_name, data)) |> List.to_tuple()
        {:error, err} -> {:error, err}
      end
    end

    def eth_send_helper(address, abi, method_name, args, options) do
      encoded_options =
        ExW3.encode_options(
          options,
          [:gas, :gasPrice, :value, :nonce]
        )

      ExW3.eth_send([
        Map.merge(
          %{
            to: address,
            data: "0x#{ExW3.encode_method_call(abi, method_name, args)}"
          },
          Map.merge(options, encoded_options)
        )
      ])
    end

    defp register_helper(contract_info) do
      if contract_info[:abi] do
        contract_info ++ init_events(contract_info[:abi])
      else
        raise "ABI not provided upon initialization"
      end
    end

    # Options' checkers

    defp check_option(nil, error_atom), do: {:error, error_atom}
    defp check_option([], error_atom), do: {:error, error_atom}
    defp check_option([head | _tail], _atom) when head != nil, do: {:ok, head}
    defp check_option([_head | tail], atom), do: check_option(tail, atom)
    defp check_option(value, _atom), do: {:ok, value}

    # Casts

    def handle_cast({:at, {name, address}}, state) do
      contract_info = state[name]
      {:noreply, Map.put(state, name, contract_info ++ [address: address])}
    end

    def handle_cast({:register, {name, contract_info}}, state) do
      {:noreply, Map.put(state, name, register_helper(contract_info))}
    end

    def handle_cast({:uninstall_filter, filter_id}, state) do
      ExW3.uninstall_filter(filter_id)
      {:noreply, Map.put(state, :filters, Map.delete(state[:filters], filter_id))}
    end

    # Calls

    defp filter_topics_helper(event_signature, event_data, topic_types, topic_names) do
      topics =
        if is_map(event_data[:topics]) do
          Enum.map(topic_names, fn name ->
            event_data[:topics][String.to_atom(name)]
          end)
        else
          event_data[:topics]
        end

      if topics do
        formatted_topics =
          Enum.map(0..(length(topics) - 1), fn i ->
            topic = Enum.at(topics, i)

            if topic do
              if is_list(topic) do
                topic_type = Enum.at(topic_types, i)

                Enum.map(topic, fn t ->
                  "0x" <> (ExW3.encode_data(topic_type, [t]) |> Base.encode16(case: :lower))
                end)
              else
                topic_type = Enum.at(topic_types, i)
                "0x" <> (ExW3.encode_data(topic_type, [topic]) |> Base.encode16(case: :lower))
              end
            else
              topic
            end
          end)

        [event_signature] ++ formatted_topics
      else
        [event_signature]
      end
    end

    def from_block_helper(event_data) do
      if event_data[:fromBlock] do
        new_from_block =
          if Enum.member?(["latest", "earliest", "pending"], event_data[:fromBlock]) do
            event_data[:fromBlock]
          else
            ExW3.encode_data("(uint256)", [event_data[:fromBlock]])
          end

        Map.put(event_data, :fromBlock, new_from_block)
      else
        event_data
      end
    end

    defp param_helper(event_data, key) do
      if event_data[key] do
        new_param =
          if Enum.member?(["latest", "earliest", "pending"], event_data[key]) do
            event_data[key]
          else
            "0x" <>
              (ExW3.encode_data("(uint256)", [event_data[key]]) |> Base.encode16(case: :lower))
          end

        Map.put(event_data, key, new_param)
      else
        event_data
      end
    end

    defp event_data_format_helper(event_data) do
      event_data
      |> param_helper(:fromBlock)
      |> param_helper(:toBlock)
      |> Map.delete(:topics)
    end

    def get_event_attributes(state, contract_name, event_name) do
      contract_info = state[contract_name]
      contract_info[:events][contract_info[:event_names][event_name]]
    end

    defp extract_non_indexed_fields(data, names, signature) do
      Enum.zip(names, ExW3.decode_event(data, signature)) |> Enum.into(%{})
    end

    defp format_log_data(log, event_attributes) do
      non_indexed_fields =
        extract_non_indexed_fields(
          Map.get(log, "data"),
          event_attributes[:non_indexed_names],
          event_attributes[:signature]
        )

      indexed_fields =
        if length(log["topics"]) > 1 do
          [_head | tail] = log["topics"]

          decoded_topics =
            Enum.map(0..(length(tail) - 1), fn i ->
              topic_type = Enum.at(event_attributes[:topic_types], i)
              topic_data = Enum.at(tail, i)

              {decoded} = ExW3.decode_data(topic_type, topic_data)

              decoded
            end)

          Enum.zip(event_attributes[:topic_names], decoded_topics) |> Enum.into(%{})
        else
          %{}
        end

      new_data = Map.merge(indexed_fields, non_indexed_fields)

      Map.put(log, "data", new_data)
    end

    def handle_call({:filter, {contract_name, event_name, event_data}}, _from, state) do
      contract_info = state[contract_name]

      event_signature = contract_info[:event_names][event_name]
      topic_types = contract_info[:events][event_signature][:topic_types]
      topic_names = contract_info[:events][event_signature][:topic_names]

      topics = filter_topics_helper(event_signature, event_data, topic_types, topic_names)

      payload =
        Map.merge(
          %{address: contract_info[:address], topics: topics},
          event_data_format_helper(event_data)
        )

      filter_id = ExW3.new_filter(payload)

      {:reply, {:ok, filter_id},
       Map.put(
         state,
         :filters,
         Map.put(state[:filters], filter_id, %{
           contract_name: contract_name,
           event_name: event_name
         })
       )}
    end

    def handle_call({:get_filter_changes, filter_id}, _from, state) do
      filter_info = Map.get(state[:filters], filter_id)

      event_attributes =
        get_event_attributes(state, filter_info[:contract_name], filter_info[:event_name])

      logs = ExW3.get_filter_changes(filter_id)

      formatted_logs =
        if logs != [] do
          Enum.map(logs, fn log ->
            formatted_log =
              Enum.reduce(
                [
                  ExW3.keys_to_decimal(log, [
                    "blockNumber",
                    "logIndex",
                    "transactionIndex",
                    "transactionLogIndex"
                  ]),
                  format_log_data(log, event_attributes)
                ],
                &Map.merge/2
              )

            formatted_log
          end)
        else
          logs
        end

      {:reply, {:ok, formatted_logs}, state}
    end

    def handle_call({:deploy, {name, args}}, _from, state) do
      contract_info = state[name]

      with {:ok, _} <- check_option(args[:options][:from], :missing_sender),
           {:ok, _} <- check_option(args[:options][:gas], :missing_gas),
           {:ok, bin} <- check_option([state[:bin], args[:bin]], :missing_binary) do
        {contract_addr, tx_hash} = deploy_helper(bin, contract_info[:abi], args)
        result = {:ok, contract_addr, tx_hash}
        {:reply, result, state}
      else
        err -> {:reply, err, state}
      end
    end

    def handle_call({:address, name}, _from, state) do
      {:reply, state[name][:address], state}
    end

    def handle_call({:call, {contract_name, method_name, args}}, _from, state) do
      contract_info = state[contract_name]

      with {:ok, address} <- check_option(contract_info[:address], :missing_address) do
        result = eth_call_helper(address, contract_info[:abi], Atom.to_string(method_name), args)
        {:reply, result, state}
      else
        err -> {:reply, err, state}
      end
    end

    def handle_call({:send, {contract_name, method_name, args, options}}, _from, state) do
      contract_info = state[contract_name]

      with {:ok, address} <- check_option(contract_info[:address], :missing_address),
           {:ok, _} <- check_option(options[:from], :missing_sender),
           {:ok, _} <- check_option(options[:gas], :missing_gas) do
        result =
          eth_send_helper(
            address,
            contract_info[:abi],
            Atom.to_string(method_name),
            args,
            options
          )

        {:reply, result, state}
      else
        err -> {:reply, err, state}
      end
    end

    def handle_call({:tx_receipt, {contract_name, tx_hash}}, _from, state) do
      contract_info = state[contract_name]

      {:ok, receipt} = ExW3.tx_receipt(tx_hash)

      events = contract_info[:events]
      logs = receipt["logs"]

      formatted_logs =
        Enum.map(logs, fn log ->
          topic = Enum.at(log["topics"], 0)
          event_attributes = Map.get(events, topic)

          if event_attributes do
            non_indexed_fields =
              Enum.zip(
                event_attributes[:non_indexed_names],
                ExW3.decode_event(log["data"], event_attributes[:signature])
              )
              |> Enum.into(%{})

            if length(log["topics"]) > 1 do
              [_head | tail] = log["topics"]

              decoded_topics =
                Enum.map(0..(length(tail) - 1), fn i ->
                  topic_type = Enum.at(event_attributes[:topic_types], i)
                  topic_data = Enum.at(tail, i)

                  {decoded} = ExW3.decode_data(topic_type, topic_data)

                  decoded
                end)

              indexed_fields =
                Enum.zip(event_attributes[:topic_names], decoded_topics) |> Enum.into(%{})

              Map.merge(indexed_fields, non_indexed_fields)
            else
              non_indexed_fields
            end
          else
            nil
          end
        end)

      {:reply, {:ok, {receipt, formatted_logs}}, state}
    end
  end
end
