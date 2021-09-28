defmodule Web3x.RpcTest do
  use ExUnit.Case

  describe ".accounts" do
    test "returns a list from the eth_accounts JSON-RPC endpoint" do
      assert Web3x.accounts() |> is_list
    end

    test "can override the http endpoint" do
      assert Web3x.accounts(url: Ethereumex.Config.rpc_url()) |> is_list
      assert Web3x.accounts(url: "https://localhost:1234") == {:error, :econnrefused}
    end
  end

  describe ".block_number" do
    test "returns the integer block number from the eth_blockNumber JSON-RPC endpoint" do
      assert {:ok, bn} = Web3x.block_number()
      assert bn |> is_integer
    end

    test "can override the http endpoint" do
      assert {:ok, _} = Web3x.block_number(url: Ethereumex.Config.rpc_url())
      assert Web3x.block_number(url: "https://localhost:1234") == {:error, :econnrefused}
    end
  end

  describe ".balance" do
    test "returns the latest integer balance from the eth_getBalance JSON-RPC endpoint" do
      account = Web3x.accounts() |> Enum.at(0)
      assert Web3x.balance(account) |> is_integer
    end

    test "can override the http endpoint" do
      account = Web3x.accounts() |> Enum.at(0)
      assert Web3x.balance(account, url: Ethereumex.Config.rpc_url()) |> is_integer
      assert Web3x.balance(account, url: "https://localhost:1234") == {:error, :econnrefused}
    end
  end
end
