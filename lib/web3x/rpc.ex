defmodule Web3x.Rpc do
  import Web3x.Client

  @type invalid_hex_string_error :: Web3x.Utils.invalid_hex_string_error()
  @type request_error :: Ethereumex.Client.Behaviour.error()
  @type opts :: {:url, String.t()}
  @type hex_block_number :: String.t()
  @type latest :: String.t()
  @type earliest :: String.t()
  @type pending :: String.t()

  @doc "returns all available accounts"
  @spec accounts() :: list()
  @spec accounts([opts]) :: list()
  def accounts(opts \\ []) do
    case call_client(:eth_accounts, [opts]) do
      {:ok, accounts} -> accounts
      err -> err
    end
  end

  @doc "Returns the current block number"
  @spec block_number() :: {:ok, non_neg_integer} | {:error, Web3x.Utils.invalid_hex_string()}
  @spec block_number([opts]) :: {:ok, non_neg_integer} | {:error, Web3x.Utils.invalid_hex_string()}
  def block_number(opts \\ []) do
    case call_client(:eth_block_number, [opts]) do
      {:ok, hex_block_number} -> Web3x.Utils.hex_to_integer(hex_block_number)
      err -> err
    end
  end

  @doc "Returns current balance of account"
  @spec balance(binary()) :: integer() | {:error, any()}
  @spec balance(binary(), [opts]) :: integer() | {:error, any()}
  def balance(account, opts \\ []) do
    case call_client(:eth_get_balance, [account, "latest", opts]) do
      {:ok, hex_balance} ->
        {:ok, balance} = Web3x.Utils.hex_to_integer(hex_balance)
        balance

      err ->
        err
    end
  end

  @doc "Returns transaction receipt for specified transaction hash(id)"
  @spec tx_receipt(binary()) :: {:ok, map()} | {:error, any()}
  def tx_receipt(tx_hash) do
    case call_client(:eth_get_transaction_receipt, [tx_hash]) do
      {:ok, nil} ->
        {:error, :not_mined}

      {:ok, receipt} ->
        normalized_receipt =
          Web3x.Normalize.transform_to_integer(receipt, ~w(blockNumber cumulativeGasUsed gasUsed))

        {:ok, Map.merge(receipt, normalized_receipt)}

      err ->
        {:error, err}
    end
  end

  @doc "Returns block data for specified block number"
  @spec block(integer()) :: any() | {:error, any()}
  def block(block_number) do
    case call_client(:eth_get_block_by_number, [block_number, true]) do
      {:ok, block} -> block
      err -> err
    end
  end

  @doc "Creates a new filter, returns filter id. For more sophisticated use, prefer Web3x.Contract.filter."
  @spec new_filter(map()) :: binary() | {:error, any()}
  def new_filter(map) do
    case call_client(:eth_new_filter, [map]) do
      {:ok, filter_id} -> filter_id
      err -> err
    end
  end

  @doc "Gets event changes (logs) by filter. Unlike Web3x.Contract.get_filter_changes it does not return the data in a formatted way"
  @spec get_filter_changes(binary()) :: any()
  def get_filter_changes(filter_id) do
    case call_client(:eth_get_filter_changes, [filter_id]) do
      {:ok, changes} -> changes
      err -> err
    end
  end

  @type log_filter :: %{
          optional(:address) => String.t(),
          optional(:fromBlock) => hex_block_number | latest | earliest | pending,
          optional(:toBlock) => hex_block_number | latest | earliest | pending,
          optional(:topics) => [String.t()],
          optional(:blockhash) => String.t()
        }

  @spec get_logs(log_filter, [opts]) :: {:ok, list} | {:error, term} | request_error
  def get_logs(filter, opts \\ []) do
    with {:ok, _} = result <- call_client(:eth_get_logs, [filter, opts]) do
      result
    else
      err -> err
    end
  end

  @doc "Uninstalls filter from the ethereum node"
  @spec uninstall_filter(binary()) :: boolean() | {:error, any()}
  def uninstall_filter(filter_id) do
    case call_client(:eth_uninstall_filter, [filter_id]) do
      {:ok, result} -> result
      err -> err
    end
  end

  @doc "Mines number of blocks specified. Default is 1"
  @spec mine(integer()) :: any() | {:error, any()}
  def mine(num_blocks \\ 1) do
    for _ <- 0..(num_blocks - 1) do
      call_client(:request, ["evm_mine", [], []])
    end
  end

  @doc "Using the personal api, returns list of accounts."
  @spec personal_list_accounts(list()) :: {:ok, list()} | {:error, any()}
  def personal_list_accounts(opts \\ []) do
    call_client(:request, ["personal_listAccounts", [], opts])
  end

  @doc "Using the personal api, this method creates a new account with the passphrase, and returns new account address."
  @spec personal_new_account(binary(), list()) :: {:ok, binary()} | {:error, any()}
  def personal_new_account(password, opts \\ []) do
    call_client(:request, ["personal_newAccount", [password], opts])
  end

  @doc "Using the personal api, this method unlocks account using the passphrase provided, and returns a boolean."
  @spec personal_unlock_account(binary(), list()) :: {:ok, boolean()} | {:error, any()}
  ### E.g. Web3x.personal_unlock_account(["0x1234","Password",30], [])
  def personal_unlock_account(params, opts \\ []) do
    call_client(:request, ["personal_unlockAccount", params, opts])
  end

  @doc "Using the personal api, this method sends a transaction and signs it in one call, and returns a transaction id hash."
  @spec personal_send_transaction(map(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  def personal_send_transaction(param_map, passphrase, opts \\ []) do
    call_client(:request, ["personal_sendTransaction", [param_map, passphrase], opts])
  end

  @doc "Using the personal api, this method signs a transaction, and returns the signed transaction."
  @spec personal_sign_transaction(map(), binary(), list()) :: {:ok, map()} | {:error, any()}
  def personal_sign_transaction(param_map, passphrase, opts \\ []) do
    call_client(:request, ["personal_signTransaction", [param_map, passphrase], opts])
  end

  @doc "Using the personal api, this method calculates an Ethereum specific signature, and returns that signature."
  @spec personal_sign(binary(), binary(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  def personal_sign(data, address, passphrase, opts \\ []) do
    call_client(:request, ["personal_sign", [data, address, passphrase], opts])
  end

  @doc "Using the personal api, this method returns the address associated with the private key that was used to calculate the signature with personal_sign."
  @spec personal_ec_recover(binary(), binary(), []) :: {:ok, binary()} | {:error, any()}
  def personal_ec_recover(data0, data1, opts \\ []) do
    call_client(:request, ["personal_ecRecover", [data0, data1], opts])
  end

  @doc "Calculates an Ethereum specific signature and signs the data provided, using the accounts private key"
  @spec eth_sign(binary(), binary(), list()) :: {:ok, binary()} | {:error, any()}
  def eth_sign(data0, data1, opts \\ []) do
    call_client(:request, ["eth_sign", [data0, data1], opts])
  end

  @doc "Simple eth_call to client. Recommended to use Web3x.Contract.call instead."
  @spec eth_call(list()) :: any()
  def eth_call(arguments) do
    call_client(:eth_call, arguments)
  end

  @doc "Simple eth_send_transaction. Recommended to use Web3x.Contract.send instead."
  @spec eth_send(list()) :: any()
  def eth_send(arguments) do
    call_client(:eth_send_transaction, arguments)
  end
end
