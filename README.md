<p align="center">
  <img src="./exw3_logo.jpg"/>
</p>

## Installation

  1. Add exw3 to your list of dependencies in mix.exs:

        def deps do
          [{:exw3, "~> 0.1.0"}]
        end

  2. Ensure exw3 is started before your application:

        def application do
          [applications: [:exw3]]
        end

## Overview

ExW3 is a wrapper around ethereumex to provide a high level, and user friendly json rpc api. It currently only supports Http. The primary feature it provides is a handy abstraction for working with smart contracts.

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
["0xb5c17637ccc1a5d91715429de76949fbe49d36f0",
 "0xecf00f60a29acf81d7fdf696fd2ca1fa82b623b0",
 "0xbf11365685e07ad86387098f27204700d7568ee2",
 "0xba76d611c29fb25158e5a7409cb627cf1bd220cf",
 "0xbb209f51ef097cc5ca320264b5373a48f7ee0fba",
 "0x31b7a2c8b2f82a92bf4cb5fd13971849c6c956fc",
 "0xeb943cee8ec3723ab3a06e45dc2a75a3caa04288",
 "0x59315d9706ac567d01860d7ede03720876972162",
 "0x4dbd23f361a4df1ef5e517b68e099bf2fcc77b10",
 "0x150eb320428b9bc93453b850b4ea454a35308f17"]
iex(2)> ExW3.balance(Enum.at(accounts, 0))
99999999999962720359
iex(3)> ExW3.block_number()
835
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
iex(5)> ExW3.Contract.start_link(SimpleStorage, abi: simple_storage_abi)
{:ok, #PID<0.239.0>}
iex(6)> {:ok, address} = ExW3.Contract.deploy(SimpleStorage, bin: ExW3.load_bin("test/examples/build/SimpleStorage.bin"), options: %{gas: 300000, from: Enum.at(accounts, 0)})
{:ok, "0xd99306b81bd61cb0ecdd3f2c946af513b3395088"}
iex(7)> ExW3.Contract.at(SimpleStorage, address)
:ok
iex(8)> ExW3.Contract.call(SimpleStorage, :get)
{:ok, 0}
iex(9)> ExW3.Contract.send(SimpleStorage, :set, [1], %{from: Enum.at(accounts, 0)})
{:ok, "0xb7e9cbdd2cec8ca017e675059a3af063d754496c960f156e1a41fe51ea82f3b8"}
iex(10)> ExW3.Contract.call(SimpleStorage, :get)                                
{:ok, 1}
```

## Compiling Solidity

Ensure you have solc installed:

```
solc --version
```

Then if you've made changes to the example contracts you can compile them like this:
```
mix solc
```