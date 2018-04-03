defmodule EXW3 do

  defmodule Contract do
    use Agent
    
    def at(abi, address) do
      { :ok, pid } = Agent.start_link(fn -> %{abi: abi, address: address} end)
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
      { :ok, bin} = File.read(Path.join(System.cwd(), bin_filename))
      tx = %{
        from: options[:from],
        data: bin,
        gas: options[:gas]
      }
      { :ok, tx_receipt_id} = Ethereumex.HttpClient.eth_send_transaction(tx)
      { :ok, tx_receipt} = Ethereumex.HttpClient.eth_get_transaction_receipt(tx_receipt_id)

      tx_receipt["contractAddress"]
    end

    def method(contract_agent, name) do
      if get(contract_agent, :abi)[name]["constant"] do
        Ethereumex.HttpClient.eth_call(%{
          to: get(contract_agent, :address),
          data: EXW3.encode(get(contract_agent, :abi), name, [])
        })
      else
        
        "foobar"
      end
    end

  end

  def accounts do
    case Ethereumex.HttpClient.eth_accounts do
      {:ok, accounts} -> accounts
      err -> err
    end
  end

  def reformat_abi abi do
    Map.new Enum.map(abi, fn x -> {x["name"], x} end)
  end

  def load_abi file_path do
    file = File.read Path.join(System.cwd, file_path)
    case file do
      {:ok, abi} -> reformat_abi Poison.Parser.parse! abi
      err -> err
    end
  end

  def encode abi, name, args do
    inputs = Enum.map abi[name]["inputs"], fn x -> x["type"] end
    fn_signature = Enum.join [name, "(", Enum.join(inputs, ","), ")"]
    ABI.encode(fn_signature, args) |> :binary.decode_unsigned
  end
end