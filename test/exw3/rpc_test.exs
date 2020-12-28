defmodule ExW3.RpcTest do
  use ExUnit.Case

  describe ".accounts" do
    test "returns a list from the eth_accounts JSON-RPC endpoint" do
      assert ExW3.accounts() |> is_list
    end

    test "can override the http endpoint" do
      assert ExW3.accounts(url: Ethereumex.Config.rpc_url()) |> is_list
      assert ExW3.accounts(url: "https://localhost:1234") == {:error, :econnrefused}
    end
  end

  describe ".block_number" do
    test "returns the integer block number from the eth_blockNumber JSON-RPC endpoint" do
      assert {:ok, bn} = ExW3.block_number()
      assert bn |> is_integer
    end

    test "can override the http endpoint" do
      assert {:ok, _} = ExW3.block_number(url: Ethereumex.Config.rpc_url())
      assert ExW3.block_number(url: "https://localhost:1234") == {:error, :econnrefused}
    end
  end

  describe ".balance" do
    test "returns the latest integer balance from the eth_getBalance JSON-RPC endpoint" do
      account = ExW3.accounts() |> Enum.at(0)
      assert ExW3.balance(account) |> is_integer
    end

    test "can override the http endpoint" do
      account = ExW3.accounts() |> Enum.at(0)
      assert ExW3.balance(account, url: Ethereumex.Config.rpc_url()) |> is_integer
      assert ExW3.balance(account, url: "https://localhost:1234") == {:error, :econnrefused}
    end
  end
end
