defmodule ExW3 do
  defdelegate accounts(opts \\ []), to: ExW3.Rpc
  defdelegate block_number(opts \\ []), to: ExW3.Rpc
  defdelegate balance(account), to: ExW3.Rpc
  defdelegate tx_receipt(tx_hash), to: ExW3.Rpc
  defdelegate block(block_number), to: ExW3.Rpc
  defdelegate new_filter(map), to: ExW3.Rpc
  defdelegate get_filter_changes(filter_id), to: ExW3.Rpc
  defdelegate get_logs(filter, opts \\ []), to: ExW3.Rpc
  defdelegate uninstall_filter(filter_id), to: ExW3.Rpc
  defdelegate mine(num_blocks \\ 1), to: ExW3.Rpc
  defdelegate personal_list_accounts(opts \\ []), to: ExW3.Rpc
  defdelegate personal_new_account(password, opts \\ []), to: ExW3.Rpc
  defdelegate personal_unlock_account(params, opts \\ []), to: ExW3.Rpc
  defdelegate personal_send_transaction(param_map, passphrase, opts \\ []), to: ExW3.Rpc
  defdelegate personal_sign_transaction(param_map, passphrase, opts \\ []), to: ExW3.Rpc
  defdelegate personal_sign(data, address, passphrase, opts \\ []), to: ExW3.Rpc
  defdelegate personal_ec_recover(data0, data1, opts \\ []), to: ExW3.Rpc
  defdelegate eth_sign(data0, data1, opts \\ []), to: ExW3.Rpc
  defdelegate eth_call(arguments), to: ExW3.Rpc
  defdelegate eth_send(arguments), to: ExW3.Rpc
end
