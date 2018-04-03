defmodule EXW3Test do
  use ExUnit.Case
  doctest EXW3

  setup_all do
    simple_storage_abi = EXW3.load_abi("test/examples/build/SimpleStorage.abi")
    %{simple_storage_abi: simple_storage_abi}
  end

  test "loads abi", context do
    assert is_map context[:simple_storage_abi]
  end

  test "encodes value and sends it", context do
    tx = %{
      data: EXW3.encode(context[:simple_storage_abi], "get", [])
    }
    
    tx
    |> Kernel.inspect
    |> IO.puts 
  end

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "greets the world" do
    assert EXW3.hello() == :world
  end

  test "gets accounts" do
    assert EXW3.accounts |> is_list
  end

  # test "testing simple storage" do
  #   SimpleStorageTester.test_simple_storage "test/examples/build/SimpleStorage.abi"
  # end

  # test "get value" do
  #   abi = EXW3.load_abi "test/examples/build/SimpleStorage.abi"

  #   |> Kernel.inspect
  #   |> IO.puts
  # end
end