defmodule ExW3 do
  @spec accounts() :: list()
  @doc "returns all available accounts"
  def accounts do
    case ExW3.Client.call_client(:eth_accounts) do
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
    case ExW3.Client.call_client(:eth_block_number) do
      {:ok, block_number} ->
        block_number |> to_decimal

      err ->
        err
    end
  end

  @spec balance(binary()) :: integer() | {:error, any()}
  @doc "Returns current balance of account"
  def balance(account) do
    case ExW3.Client.call_client(:eth_get_balance, [account]) do
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
    case ExW3.Client.call_client(:eth_get_transaction_receipt, [tx_hash]) do
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
    case ExW3.Client.call_client(:eth_get_block_by_number, [block_number, true]) do
      {:ok, block} -> block
      err -> err
    end
  end

  @spec new_filter(map()) :: binary() | {:error, any()}
  @doc "Creates a new filter, returns filter id. For more sophisticated use, prefer ExW3.Contract.filter."
  def new_filter(map) do
    case ExW3.Client.call_client(:eth_new_filter, [map]) do
      {:ok, filter_id} -> filter_id
      err -> err
    end
  end

  @spec get_filter_changes(binary()) :: any()
  @doc "Gets event changes (logs) by filter. Unlike ExW3.Contract.get_filter_changes it does not return the data in a formatted way"
  def get_filter_changes(filter_id) do
    case ExW3.Client.call_client(:eth_get_filter_changes, [filter_id]) do
      {:ok, changes} -> changes
      err -> err
    end
  end

  @spec uninstall_filter(binary()) :: boolean() | {:error, any()}
  @doc "Uninstalls filter from the ethereum node"
  def uninstall_filter(filter_id) do
    case ExW3.Client.call_client(:eth_uninstall_filter, [filter_id]) do
      {:ok, result} -> result
      err -> err
    end
  end

  @type invalid_hex_string_error :: ExW3.Utils.invalid_hex_string_error()
  @type request_error :: Ethereumex.Client.Behaviour.error()
  @type opts :: keyword
  @type latest :: String.t()
  @type earliest :: String.t()
  @type pending :: String.t()
  @type hex_block_number :: String.t()
  @type log_filter :: %{
          optional(:address) => String.t(),
          optional(:fromBlock) => hex_block_number | latest | earliest | pending,
          optional(:toBlock) => hex_block_number | latest | earliest | pending,
          optional(:topics) => [String.t()],
          optional(:blockhash) => String.t()
        }

  @spec get_logs(log_filter, opts) :: {:ok, list} | {:error, term} | request_error
  def get_logs(filter, opts \\ []) do
    with {:ok, _} = result <- ExW3.Client.call_client(:eth_get_logs, [filter, opts]) do
      result
    else
      err -> err
    end
  end

  @spec mine(integer()) :: any() | {:error, any()}
  @doc "Mines number of blocks specified. Default is 1"
  def mine(num_blocks \\ 1) do
    for _ <- 0..(num_blocks - 1) do
      ExW3.Client.call_client(:request, ["evm_mine", [], []])
    end
  end

  @spec personal_list_accounts(list()) :: {:ok, list()} | {:error, any()}
  @doc "Using the personal api, returns list of accounts."
  def personal_list_accounts(opts \\ []) do
    ExW3.Client.call_client(:request, ["personal_listAccounts", [], opts])
  end

  @spec personal_new_account(binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method creates a new account with the passphrase, and returns new account address."
  def personal_new_account(password, opts \\ []) do
    ExW3.Client.call_client(:request, ["personal_newAccount", [password], opts])
  end

  @spec personal_unlock_account(binary(), list()) :: {:ok, boolean()} | {:error, any()}
  @doc "Using the personal api, this method unlocks account using the passphrase provided, and returns a boolean."
  ### E.g. ExW3.personal_unlock_account(["0x1234","Password",30], [])
  def personal_unlock_account(params, opts \\ []) do
    ExW3.Client.call_client(:request, ["personal_unlockAccount", params, opts])
  end

  @spec personal_send_transaction(map(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method sends a transaction and signs it in one call, and returns a transaction id hash."
  def personal_send_transaction(param_map, passphrase, opts \\ []) do
    ExW3.Client.call_client(:request, ["personal_sendTransaction", [param_map, passphrase], opts])
  end

  @spec personal_sign_transaction(map(), binary(), list()) :: {:ok, map()} | {:error, any()}
  @doc "Using the personal api, this method signs a transaction, and returns the signed transaction."
  def personal_sign_transaction(param_map, passphrase, opts \\ []) do
    ExW3.Client.call_client(:request, ["personal_signTransaction", [param_map, passphrase], opts])
  end

  @spec personal_sign(binary(), binary(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method calculates an Ethereum specific signature, and returns that signature."
  def personal_sign(data, address, passphrase, opts \\ []) do
    ExW3.Client.call_client(:request, ["personal_sign", [data, address, passphrase], opts])
  end

  @spec personal_ec_recover(binary(), binary(), []) :: {:ok, binary()} | {:error, any()}
  @doc "Using the personal api, this method returns the address associated with the private key that was used to calculate the signature with personal_sign."
  def personal_ec_recover(data0, data1, opts \\ []) do
    ExW3.Client.call_client(:request, ["personal_ecRecover", [data0, data1], opts])
  end

  @spec eth_sign(binary(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  @doc "Calculates an Ethereum specific signature and signs the data provided, using the accounts private key"
  def eth_sign(data0, data1, opts \\ []) do
    ExW3.Client.call_client(:request, ["eth_sign", [data0, data1], opts])
  end

  @spec eth_call(list()) :: any()
  @doc "Simple eth_call to client. Recommended to use ExW3.Contract.call instead."
  def eth_call(arguments) do
    ExW3.Client.call_client(:eth_call, arguments)
  end

  @spec eth_send(list()) :: any()
  @doc "Simple eth_send_transaction. Recommended to use ExW3.Contract.send instead."
  def eth_send(arguments) do
    ExW3.Client.call_client(:eth_send_transaction, arguments)
  end
end
