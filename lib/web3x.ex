defmodule Web3x do
  defdelegate accounts(opts \\ []), to: Web3x.Rpc
  defdelegate block_number(opts \\ []), to: Web3x.Rpc
  defdelegate balance(account, opts \\ []), to: Web3x.Rpc
  defdelegate tx_receipt(tx_hash), to: Web3x.Rpc
  defdelegate block(block_number), to: Web3x.Rpc
  defdelegate new_filter(map), to: Web3x.Rpc
  defdelegate get_filter_changes(filter_id), to: Web3x.Rpc
  defdelegate get_logs(filter, opts \\ []), to: Web3x.Rpc
  defdelegate uninstall_filter(filter_id), to: Web3x.Rpc
  defdelegate mine(num_blocks \\ 1), to: Web3x.Rpc
  defdelegate personal_list_accounts(opts \\ []), to: Web3x.Rpc
  defdelegate personal_new_account(password, opts \\ []), to: Web3x.Rpc
  defdelegate personal_unlock_account(params, opts \\ []), to: Web3x.Rpc
  defdelegate personal_send_transaction(param_map, passphrase, opts \\ []), to: Web3x.Rpc
  defdelegate personal_sign_transaction(param_map, passphrase, opts \\ []), to: Web3x.Rpc
  defdelegate personal_sign(data, address, passphrase, opts \\ []), to: Web3x.Rpc
  defdelegate personal_ec_recover(data0, data1, opts \\ []), to: Web3x.Rpc
  defdelegate eth_sign(data0, data1, opts \\ []), to: Web3x.Rpc
  defdelegate eth_call(arguments), to: Web3x.Rpc
  defdelegate eth_send(arguments), to: Web3x.Rpc
end
