defmodule Web3x.ClientTest do
  use ExUnit.Case

  test ".call_client/1 calls the JSON-RPC method with an empty list of arguments" do
    assert {:ok, hex} = Web3x.Client.call_client(:eth_block_number)
    assert "0x" <> _ = hex
  end

  test ".call_client/2 calls the JSON-RPC method with the given arguments" do
    assert {:ok, accounts} = Web3x.Client.call_client(:eth_accounts)
    assert Enum.count(accounts) > 0
    assert ["0x" <> _ = account | _] = accounts

    assert {:ok, balance} = Web3x.Client.call_client(:eth_get_balance, [account])
    assert "0x" <> _ = balance
  end

  test ".call_client/2 can specifiy a http url with & without params" do
    assert {:ok, accounts} =
             Web3x.Client.call_client(:eth_accounts, [[url: Ethereumex.Config.rpc_url()]])

    account = Enum.at(accounts, 0)

    assert {:ok, "0x" <> _} =
             Web3x.Client.call_client(:eth_get_balance, [
               account,
               "latest",
               [url: Ethereumex.Config.rpc_url()]
             ])

    assert Web3x.Client.call_client(:eth_get_balance, [account, "latest", [url: "unsupported"]]) ==
             {:error, :invalid_client_type}

    assert Web3x.Client.call_client(:eth_get_balance, [
             account,
             "latest",
             [url: "http://localhost:1234"]
           ]) ==
             {:error, :econnrefused}

    assert Web3x.Client.call_client(:eth_get_balance, [
             account,
             "latest",
             [url: "https://localhost:1234"]
           ]) ==
             {:error, :econnrefused}
  end
end
