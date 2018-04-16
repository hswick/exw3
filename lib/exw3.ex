defmodule ExW3 do
  def reformat_abi(abi) do
    Map.new(Enum.map(abi, fn x -> {x["name"], x} end))
  end

  def load_abi(file_path) do
    file = File.read(Path.join(System.cwd(), file_path))

    case file do
      {:ok, abi} -> reformat_abi(Poison.Parser.parse!(abi))
      err -> err
    end
  end

  def decode_output(abi, name, output) do
    {:ok, trim_output} =
      String.slice(output, 2..String.length(output)) |> Base.decode16(case: :lower)

    output_types = Enum.map(abi[name]["outputs"], fn x -> x["type"] end)
    output_signature = Enum.join([name, "(", Enum.join(output_types, ")"), ")"])
    ABI.decode(output_signature, trim_output)
  end

  def encode_input(abi, name, input) do
    if abi[name]["inputs"] do
      input_types = Enum.map(abi[name]["inputs"], fn x -> x["type"] end)
      input_signature = Enum.join([name, "(", Enum.join(input_types, ","), ")"])
      ABI.encode(input_signature, input) |> Base.encode16(case: :lower)
    else
      raise "#{name} method not found with the given abi"
    end
  end

  def bytes_to_string bytes do
    bytes
    |> Base.encode16(case: :lower)
    |> String.replace_trailing("0", "")
    |> Hexate.decode
  end

  def accounts do
    case Ethereumex.HttpClient.eth_accounts() do
      {:ok, accounts} -> accounts
      err -> err
    end
  end

  # Converts ethereum hex string to decimal number
  def to_decimal(hex_string) do
    hex_string
    |> String.slice(2..-1)
    |> String.to_integer(16)
  end

  def block_number do
    case Ethereumex.HttpClient.eth_block_number() do
      {:ok, block_number} ->
        block_number |> to_decimal

      err ->
        err
    end
  end

  def balance(account) do
    case Ethereumex.HttpClient.eth_get_balance(account) do
      {:ok, balance} ->
        balance |> to_decimal

      err ->
        err
    end
  end

  def keys_to_decimal(map, keys) do
    Map.new(
      Enum.map(keys, fn k ->
        {k, Map.get(map, k) |> to_decimal}
      end)
    )
  end

  def tx_receipt(tx_hash) do
    case Ethereumex.HttpClient.eth_get_transaction_receipt(tx_hash) do
      {:ok, receipt} ->
        Map.merge receipt, keys_to_decimal(receipt, ["blockNumber", "cumulativeGasUsed", "gasUsed"])

      err ->
        err
    end
  end

  def block(block_number) do
    case Ethereumex.HttpClient.eth_get_block_by_number(block_number, true) do
      {:ok, block} -> block
      err -> err
    end
  end

  def mine(num_blocks \\ 1) do
    for _ <- 0..(num_blocks - 1) do
      Ethereumex.HttpClient.request("evm_mine", [], [])
    end
  end

  def encode_event(signature) do
    ExthCrypto.Hash.Keccak.kec(signature) |> Base.encode16(case: :lower)
  end

  defmodule Contract do
    use Agent

    def at(abi, address) do
      {:ok, pid} = Agent.start_link(fn -> %{abi: abi, address: address} end)
      pid
    end

    def get(contract, key) do
      Agent.get(contract, &Map.get(&1, key))
    end

    @doc """
    Puts the `value` for the given `key` in the `contract`.
    """
    def put(contract, key, value) do
      Agent.update(contract, &Map.put(&1, key, value))
    end

    def deploy(bin_filename, options) do
      {:ok, bin} = File.read(Path.join(System.cwd(), bin_filename))

      tx = %{
        from: options[:from],
        data: bin,
        gas: options[:gas]
      }

      {:ok, tx_receipt_id} = Ethereumex.HttpClient.eth_send_transaction(tx)
      {:ok, tx_receipt} = Ethereumex.HttpClient.eth_get_transaction_receipt(tx_receipt_id)

      tx_receipt["contractAddress"]
    end

    def method(contract_agent, method_name, args \\ [], options \\ %{}) do
      method_name = 
        case method_name |> is_atom do
          true -> Inflex.camelize(method_name, :lower)
          false -> method_name
        end

      input = ExW3.encode_input(get(contract_agent, :abi), method_name, args)

      if get(contract_agent, :abi)[method_name]["constant"] do
        {:ok, output} =
          Ethereumex.HttpClient.eth_call(%{
            to: get(contract_agent, :address),
            data: input
          })

        ([:ok] ++ ExW3.decode_output(get(contract_agent, :abi), method_name, output)) |> List.to_tuple()
      else
        Ethereumex.HttpClient.eth_send_transaction(
          Map.merge(
            %{
              to: get(contract_agent, :address),
              data: input
            },
            options
          )
        )
      end
    end
  end

  defmodule EventPublisher do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, %{block_number: ExW3.block_number(), subscribers: %MapSet{}}, name: ExW3.EventPublisher)
    end

    def init(state) do
      Registry.start_link(keys: :unique, name: Registry.ExW3.EventPubSub)
      schedule_block()
      {:ok, state}
    end

    def filter_unsubscribed(logs, state) do
      Enum.filter(logs, fn log -> MapSet.member?(state[:subscribers], log["address"]) end)
    end

    def handle_info(:block, state) do
      block_number = ExW3.block_number()
      block = ExW3.block(block_number)

      tx_receipts = Enum.map(block["transactions"], fn tx -> ExW3.tx_receipt(tx["hash"]) end)

      for logs <- Enum.map(tx_receipts, fn receipt -> receipt["logs"] end) do
        for log <- filter_unsubscribed(logs, state) do
          for topic <- log["topics"] do
            Registry.dispatch(Registry.ExW3.EventPubSub, String.slice(topic, 2..-1), fn entries ->
              for {pid, _} <- entries, do: send(pid, {:eth_event, log["data"]})
            end)
          end
        end
      end

      schedule_block()
      {:noreply, Map.merge(state, %{block_number: block_number})}
    end

    def handle_cast({:new_subscriber, {:address, address}}, state) do
      {_, new_state} = Map.get_and_update(state, :subscribers, fn subscribers -> 
        {subscribers, MapSet.put(subscribers, address)}
      end)
      {:noreply, new_state}
    end

    defp schedule_block() do
      Process.send_after(self(), :block, 1000)
    end
  end

  def decode_event(data, signature) do
    fs = ABI.FunctionSelector.decode(signature)

    #IO.inspect fs

    data
    #|> ABI.TypeDecoder.decode(fs)
  end

  defmodule EventSubscriber do
    use GenServer

    def start_link(topic, address, callback) do
      GenServer.start_link(__MODULE__, %{callback: callback, topic: topic, address: address})
    end

    def init(state) do
      encoded_event = ExW3.encode_event(state[:topic])
      Registry.register(Registry.ExW3.EventPubSub, encoded_event, [])
      GenServer.cast(ExW3.EventPublisher, {:new_subscriber, {:address, state[:address]}})
      {:ok, state}
    end

    def handle_info({:eth_event, message}, state) do
      apply state[:callback], [ExW3.decode_event(message, state[:topic])]
      {:noreply, state}
    end
  end
end
