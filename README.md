<p align="center">
  <img src="./exw3_logo.jpg"/>
</p>

## Installation

  1. Add exw3 to your list of dependencies in mix.exs:

        def deps do
          [{:exw3, "~> 0.0.1"}]
        end

  2. Ensure exw3 is started before your application:

        def application do
          [applications: [:exw3]]
        end

## Overview

ExW3 is a wrapper around ethereumex to provide a high level, and user friendly json rpc api. It currently only supports Http.

## Usage

Ensure you have an ethereum node to connect to at the specified url in your config. Any easy local testnet to use is ganache-cli:
```
ganache-cli
```

Make sure your config includes:
```elixir
config :ethereumex,
  url: "http://localhost:8545"
```

Currently ExW3 supports a handful of json rpc commands. Mostly just the useful ones. If it doesn't support those specific commands you can always use the Ethereumex commands.

```elixir
iex(1)> accounts = ExW3.accounts()                                        
["0x957e3d06f15d6fc3913a24c5c41009784a4ec683",
 "0xa9a5037dc1cba71609792e3309b57e777ae01c0f",
 "0x4944392f44d60f2f949ba241244401bd43863c1c",
 "0xc0fe85ae40d6dd480ccbf31902bdb6b90057c908",
 "0xc06f7379abb368c54059c78f9ef524d8badcb7da",
 "0x0de579fe6dcd60620e10e1ce447dfb6077306e68",
 "0x8895d7195659cbcb442825b62bb028176ab126f6",
 "0x205b8d4b9b52e9653d9ea29815bfa2ccf9f11b71",
 "0xefe82d7b1e7bed2e3bfe7b5a155cff7a5adf0dcc",
 "0x93d1f6303711e5c9fa849cfad38d5782740d39fe"]
iex(2)> ExW3.balance(Enum.at(accounts, 0))                                      
100000000000000000000
iex(3)> ExW3.block_number()            
0
iex(4)> simple_storage_abi = ExW3.load_abi("test/examples/build/SimpleStorage.abi")
%{
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
iex(5)> contract_address = ExW3.Contract.deploy("test/examples/build/SimpleStorage.bin", %{from: Enum.at(accounts, 0), gas: 150000})
"0xecac9f4000ae355c7d33481edb0fddbece502423"
iex(6)> storage_pid = ExW3.Contract.at(simple_storage_abi, contract_address) 
#PID<0.257.0>
iex(7)> ExW3.Contract.method(storage_pid, "get")
{:ok, 0}
iex(8)> ExW3.Contract.method(storage_pid, "set", [1], %{from: Enum.at(accounts, 0)})
{:ok, "0xb8a6ee58c88efcea775452a68fac20e47bda6ca933aa25dd85c4a97b0cfbf43f"}
iex(9)> ExW3.Contract.method(storage_pid, "get")                          
{:ok, 1}
```

For bonus style points you can use snake case keywords for the method names. For example:

```elixir
ExW3.Contract.method(pid, "fooBar")
```

is the same as:

```elixir
ExW3.Contract.method(pid, :foo_bar)
```


## Compiling solidity

Ensure you have solc installed:

```
solc --version
```

Then if you've made changes to the example contracts you can compile them like this:
```
mix solc
```