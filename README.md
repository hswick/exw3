# Web3x

[![Build Status](https://github.com/Metalink-App/web3x/workflows/test/badge.svg?branch=master)](https://github.com/Metalink-App/web3x/actions?query=workflow%3Atest)
[![hex.pm version](https://img.shields.io/hexpm/v/web3x.svg?style=flat)](https://hex.pm/packages/web3x)

<p align="center">
  <img src="./web3x_logo.png"/>
</p>

## Installation

```elixir
def deps do
  [
    {:web3x, "~> 0.6.2"}
  ]
end
```
## Overview

Web3x is a wrapper around ethereumex to provide a high level, user friendly json rpc api. This library is focused on providing a handy abstraction for working with smart contracts, and any other relevant utilities.

## Usage

Ensure you have an ethereum node to connect to at the specified url in your config. An easy local testnet to use is ganache-cli:
```
ganache-cli
```

Or you can use parity:
Install Parity, then run it with

```
echo > passfile
parity --chain dev --unlock=0x00a329c0648769a73afac7f9381e08fb43dbea72 --reseal-min-period 0 --password passfile
```

If Parity complains about password or missing account, try

```
parity --chain dev --unlock=0x00a329c0648769a73afac7f9381e08fb43dbea72
```

### Http

To use Ethereumex's HttpClient simply set your config like this:
```elixir
config :ethereumex,
  client_type: :http,
  url: "http://localhost:8545"
```

### Ipc

If you want to use IpcClient set your config to something like this:
```elixir
config :ethereumex,
  client_type: :ipc,
  ipc_path: "/.local/share/io.parity.ethereum/jsonrpc.ipc"
```

Provide an absolute path to the ipc socket provided by whatever Ethereum client you are running. You don't need to include the home directory, as that will be prepended to the path provided.

* NOTE : Use of Ipc is recommended, as it is more secure and significantly faster.

Currently, Ex_W3 supports a handful of json rpc commands. Primarily the ones that get used the most. If Ex_W3 doesn't provide a specific command, you can always use the [Ethereumex](https://github.com/exthereum/ethereumex) commands.

Check out the [documentation](https://hexdocs.pm/web3x/Web3x.html) for more details of the API.

### Example

```elixir
iex(1)> accounts = Web3x.accounts()
["0x00a329c0648769a73afac7f9381e08fb43dbea72"]
iex(2)> Web3x.balance(Enum.at(accounts, 0))
1606938044258990275541962092341162602522200978938292835291376
iex(3)> Web3x.block_number()
1252
iex(4)> simple_storage_abi = Web3x.Abi.load_abi("test/examples/build/SimpleStorage.abi")
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
iex(5)> Web3x.Contract.start_link
{:ok, #PID<0.265.0>}
iex(6)> Web3x.Contract.register(:SimpleStorage, abi: simple_storage_abi)
:ok
iex(7)> {:ok, address, tx_hash} = Web3x.Contract.deploy(:SimpleStorage, bin: Web3x.Abi.load_bin("test/examples/build/SimpleStorage.bin"), options: %{gas: 300_000, from: Enum.at(accounts, 0)})
{:ok, "0x22018c2bb98387a39e864cf784e76cb8971889a5",
 "0x4ea539048c01194476004ef69f407a10628bed64e88ee8f8b17b4d030d0e7cb7"}
iex(8)> Web3x.Contract.at(:SimpleStorage, address)
:ok
iex(9)> Web3x.Contract.call(:SimpleStorage, :get)
{:ok, 0}
iex(10)> Web3x.Contract.send(:SimpleStorage, :set, [1], %{from: Enum.at(accounts, 0), gas: 50_000})
{:ok, "0x88838e84a401a1d6162290a1a765507c4a83f5e050658a83992a912f42149ca5"}
iex(11)> Web3x.Contract.call(:SimpleStorage, :get)
{:ok, 1}
```

Loading Abi from Map (in case your use case stores abis in postgres or mongo as jsonb)
```elixir
iex(1)> cryptopunk_abi = cryptopunk_ecto_instance.abi # assuming this is a JSONB field parsed to a map already
iex(2)> Web3x.Contract.load_abi_map(cryptopunk_abi)
%{
 ...
}
```

## Address Type

If you are familiar with web3.js you may find the way Web3x handles addresses unintuitive. Web3x's abi encoder interprets the address type as an uint160. If you are using an address as an option to a transaction like `:from` or `:to` this will work as expected. However, if one of your smart contracts is expecting an address type for an input parameter then you will need to do this:
```elixir
a = Web3x.Utils.hex_to_integer("0x88838e84a401a1d6162290a1a765507c4a83f5e050658a83992a912f42149ca5")
```

## Events

Web3x allows the retrieval of event logs using filters or transaction receipts. In this example we will demonstrate a filter. Assume we have already deployed and registered a contract called EventTester.

```elixir
# We can optionally specify extra parameters like `:fromBlock`, and `:toBlock`
{:ok, filter_id} = Web3x.Contract.filter(:EventTester, "Simple", %{fromBlock: 42, toBlock: "latest"})

# After some point that we think there are some new changes
{:ok, changes} = Web3x.Contract.get_filter_changes(filter_id)

# We can then uninstall the filter after we are done using it
Web3x.Contract.uninstall_filter(filter_id)
```

## Indexed Events

Ethereum allows a user to add topics to filters. This means the filter will only return events with the specific index parameters. For all of the extra options see [here](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_newfilter)

If you have written your event in Solidity like this:
```
event SimpleIndex(uint256 indexed num, bytes32 indexed data, uint256 otherNum);
```

You can add a filter on which logs will be returned back to the RPC client based on the indexed fields.

Web3x allows for 2 ways of specifying these parameters (`:topics`) in two ways. The first, and probably more preferred way, is with a map:

```elixir
indexed_filter_id = Web3x.Contract.filter(
  :EventTester,
  "SimpleIndex",
  %{
    topics: %{num: 46, data: "Hello, World!"},
  }
)
```

The other option is a list (mapped version is an abstraction over this). The downside here is this is order dependent. Any values you don't want to specify must be represented with a `nil`. This approach has been included because it is the implementation of the JSON RPC spec.

```elixir
indexed_filter_id = Web3x.Contract.filter(
  :EventTester,
  "SimpleIndex",
  %{
    topics: [nil, "Hello, World!"]
  }
)
```

Here we are skipping the `num` topic, and only filtering on the `data` parameter.

NOTE!!! These two approaches are mutually exclusive, and for almost all cases you should prefer the map.

## Continuous Event Handling

In many cases, you will want some process to continuously listen for events. We can implement this functionality using a recursive function. Since Elixir uses tail call optimization, we won't have to worry about blowing up the stack.

```elixir
def listen_for_event do
  {:ok, changes} = Web3x.Contract.get_filter_changes(filter_id) # Get our changes from the blockchain
  handle_changes(changes) # Some function to deal with the data. Good place to use pattern matching.
  :timer.sleep(1000) # Some delay in milliseconds. Recommended to save bandwidth, and not spam.
  listen_for_event() # Recurse
end
```

# Compiling Solidity

To compile the test solidity contracts after making a change run this command:
```
solc --abi --bin --overwrite -o test/examples/build test/examples/contracts/*.sol
```

# Install Ganache

- [Ganache Desktop](https://github.com/trufflesuite/ganache)
- Change port to `8545` in Settings > Server.

# Deploying Contracts with Hardhat

To compile the test solidity contracts after making a change run this command:
```
npm run compile
```

To deploy the solidity contracts with a local running ganache on port `8545` running at `localhost:8545` without using `web3x` to deploy use this command
```
npm run ganache
```

# Contributing

## Test

The full test suite requires a running blockchain. You can run your own or start `openethereum` with `docker-compose`.

```bash
$ docker-compose up
$ mix test
```

## License

`web3x` is released under the [Apache 2.0 license](./LICENSE.md)

A Special Thank you to Harley Swick [@hswick](https://github.com/hswick) for creating the library `exw3` this was forked from.

Original Library [Exw3](https://github.com/hswick/exw3)
