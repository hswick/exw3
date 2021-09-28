defmodule Web3x.AbiTest do
  use ExUnit.Case

  test ".load_abi/1 returns a map keyed by function & event name" do
    assert Web3x.Abi.load_abi("test/examples/build/SimpleStorage.abi") == %{
             "get" => %{
               "constant" => true,
               "inputs" => [],
               "name" => "get",
               "outputs" => [%{"name" => "", "type" => "uint256"}],
               "payable" => false,
               "stateMutability" => "view",
               "type" => "function"
             },
             "set" => %{
               "constant" => false,
               "inputs" => [%{"name" => "_data", "type" => "uint256"}],
               "name" => "set",
               "outputs" => [],
               "payable" => false,
               "stateMutability" => "nonpayable",
               "type" => "function"
             }
           }
  end
end
