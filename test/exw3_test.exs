defmodule EXW3Test do
  use ExUnit.Case
  doctest EXW3

  setup_all do
    %{
      simple_storage_abi: EXW3.load_abi("test/examples/build/SimpleStorage.abi"), 
      accounts: EXW3.accounts
    }
  end

  test "loads abi", context do
    assert context[:simple_storage_abi] |> is_map
  end

  test "deploys contract and uses it", context do
    contract_address = EXW3.Contract.deploy(
      "test/examples/build/SimpleStorage.bin", 
      %{
          from: Enum.at(context[:accounts], 0), 
          gas: 150000
      }
    )

    contract_agent = EXW3.Contract.at context[:simple_storage_abi], contract_address

    EXW3.Contract.get contract_agent, :abi
    |> Kernel.inspect
    |> IO.puts 

    EXW3.Contract.method(contract_agent, "get")
    |> Kernel.inspect
    |> IO.puts 
  end

  test "gets accounts" do
    assert EXW3.accounts |> is_list
  end

end