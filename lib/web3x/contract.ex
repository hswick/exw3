defmodule Web3x.Contract do
  use GenServer

  @doc "Begins the Contract process to manage all interactions with smart contracts"
  @spec start_link() :: {:ok, pid()}
  def start_link(_ \\ :ok) do
    GenServer.start_link(__MODULE__, %{filters: %{}}, name: ContractManager)
  end

  @doc "Deploys contracts with given arguments"
  @spec deploy(atom(), list()) :: {:ok, binary(), binary()}
  def deploy(name, args) do
    GenServer.call(ContractManager, {:deploy, {name, args}})
  end

  @doc "Registers the contract with the ContractManager process. Only :abi is required field."
  @spec register(atom(), list()) :: :ok
  def register(name, contract_info) do
    GenServer.cast(ContractManager, {:register, {name, contract_info}})
  end

  @doc "Uninstalls the filter, and deletes the data associated with the filter id"
  @spec uninstall_filter(binary()) :: :ok
  def uninstall_filter(filter_id) do
    GenServer.cast(ContractManager, {:uninstall_filter, filter_id})
  end

  @doc "Sets the address for the contract specified by the name argument"
  @spec at(atom(), binary()) :: :ok
  def at(name, address) do
    GenServer.cast(ContractManager, {:at, {name, address}})
  end

  @doc "Returns the current Contract GenServer's address"
  @spec address(atom()) :: {:ok, binary()}
  def address(name) do
    GenServer.call(ContractManager, {:address, name})
  end

  @doc "Use a Contract's method with an eth_call"
  @spec call(atom(), atom(), list(), any()) :: {:ok, any()}
  def call(contract_name, method_name, args \\ [], timeout \\ :infinity) do
    GenServer.call(ContractManager, {:call, {contract_name, method_name, args}}, timeout)
  end

  @doc "Use a Contract's method with an eth_sendTransaction"
  @spec send(atom(), atom(), list(), map()) :: {:ok, binary()}
  def send(contract_name, method_name, args, options) do
    GenServer.call(ContractManager, {:send, {contract_name, method_name, args, options}})
  end

  @doc "Returns a formatted transaction receipt for the given transaction hash(id)"
  @spec tx_receipt(atom(), binary()) :: map()
  def tx_receipt(contract_name, tx_hash) do
    GenServer.call(ContractManager, {:tx_receipt, {contract_name, tx_hash}})
  end

  @doc "Installs a filter on the Ethereum node. This also formats the parameters, and saves relevant information to format event logs."
  @spec filter(atom(), binary(), map()) :: {:ok, binary()}
  def filter(contract_name, event_name, event_data \\ %{}) do
    GenServer.call(
      ContractManager,
      {:filter, {contract_name, event_name, event_data}}
    )
  end

  @doc "Using saved information related to the filter id, event logs are formatted properly"
  @spec get_filter_changes(binary()) :: {:ok, list()}
  def get_filter_changes(filter_id) do
    GenServer.call(
      ContractManager,
      {:get_filter_changes, filter_id}
    )
  end

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
        encoded_event_signature = Web3x.Utils.keccak256(signature)

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

          bin <>
            (Web3x.Abi.encode_data(types_signature, arguments) |> Base.encode16(case: :lower))
        else
          # IO.warn("Could not find a constructor")
          bin
        end
      else
        bin
      end

    gas = Web3x.Abi.encode_option(args[:options][:gas])
    gasPrice = Web3x.Abi.encode_option(args[:options][:gas_price])

    tx = %{
      from: args[:options][:from],
      data: "0x#{constructor_arg_data}",
      gas: gas,
      gasPrice: gasPrice
    }

    {:ok, tx_hash} = Web3x.Rpc.eth_send([tx])
    {:ok, tx_receipt} = Web3x.Rpc.tx_receipt(tx_hash)

    {tx_receipt["contractAddress"], tx_hash}
  end

  def eth_call_helper(address, abi, method_name, args) do
    result =
      Web3x.Rpc.eth_call([
        %{
          to: address,
          data: "0x#{Web3x.Abi.encode_method_call(abi, method_name, args)}"
        }
      ])

    case result do
      {:ok, data} ->
        ([:ok] ++ Web3x.Abi.decode_output(abi, method_name, data)) |> List.to_tuple()

      {:error, err} ->
        {:error, err}
    end
  end

  def eth_send_helper(address, abi, method_name, args, options) do
    encoded_options =
      Web3x.Abi.encode_options(
        options,
        [:gas, :gasPrice, :value, :nonce]
      )

    gas = Web3x.Abi.encode_option(args[:options][:gas])
    gasPrice = Web3x.Abi.encode_option(args[:options][:gas_price])

    Web3x.Rpc.eth_send([
      Map.merge(
        %{
          to: address,
          data: "0x#{Web3x.Abi.encode_method_call(abi, method_name, args)}",
          gas: gas,
          gasPrice: gasPrice
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
    contract_state = state[name]
    contract_state = Keyword.put(contract_state, :address, address)
    state = Map.put(state, name, contract_state)
    {:noreply, state}
  end

  def handle_cast({:register, {name, contract_info}}, state) do
    {:noreply, Map.put(state, name, register_helper(contract_info))}
  end

  def handle_cast({:uninstall_filter, filter_id}, state) do
    Web3x.uninstall_filter(filter_id)
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
                "0x" <> (Web3x.Abi.encode_data(topic_type, [t]) |> Base.encode16(case: :lower))
              end)
            else
              topic_type = Enum.at(topic_types, i)
              "0x" <> (Web3x.Abi.encode_data(topic_type, [topic]) |> Base.encode16(case: :lower))
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
          Web3x.Abi.encode_data("(uint256)", [event_data[:fromBlock]])
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
            (Web3x.Abi.encode_data("(uint256)", [event_data[key]])
             |> Base.encode16(case: :lower))
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
    Enum.zip(names, Web3x.Abi.decode_event(data, signature)) |> Enum.into(%{})
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

            {decoded} = Web3x.Abi.decode_data(topic_type, topic_data)

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

    filter_id = Web3x.Rpc.new_filter(payload)

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

    logs = Web3x.Rpc.get_filter_changes(filter_id)

    formatted_logs =
      if logs != [] do
        Enum.map(logs, fn log ->
          formatted_log =
            Enum.reduce(
              [
                Web3x.Normalize.transform_to_integer(log, [
                  "blockNumber",
                  "logIndex",
                  "transactionIndex"
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

    {:ok, receipt} = Web3x.tx_receipt(tx_hash)

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
              Web3x.Abi.decode_event(log["data"], event_attributes[:signature])
            )
            |> Enum.into(%{})

          if length(log["topics"]) > 1 do
            [_head | tail] = log["topics"]

            decoded_topics =
              Enum.map(0..(length(tail) - 1), fn i ->
                topic_type = Enum.at(event_attributes[:topic_types], i)
                topic_data = Enum.at(tail, i)

                {decoded} = Web3x.Abi.decode_data(topic_type, topic_data)

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
