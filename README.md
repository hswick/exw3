<p align="center">
  <img src="./exw3_logo.jpg"/>
</p>

## Installation

```elixir
def deps do
  [{:exw3, "~> 0.1.6"}]
end
```
## Overview

ExW3 is a wrapper around ethereumex to provide a high level, user friendly json rpc api. It currently only supports Http. The primary feature it provides is a handy abstraction for working with smart contracts.

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

Make sure your config includes:
```elixir
config :ethereumex,
  url: "http://localhost:8545"
```

Currently, ExW3 supports a handful of json rpc commands. Mostly just the useful ones. If it doesn't support a specific commands you can always use the [Ethereumex](https://github.com/exthereum/ethereumex) commands.

Check out the [documentation](https://hexdocs.pm/exw3/ExW3.html)

```elixir
iex(1)> accounts = ExW3.accounts()
["0x00a329c0648769a73afac7f9381e08fb43dbea72"]
iex(2)> ExW3.balance(Enum.at(accounts, 0))
1606938044258990275541962092341162602522200978938292835291376
iex(3)> ExW3.block_number()
1252
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
iex(5)> ExW3.Contract.start_link
{:ok, #PID<0.265.0>}
iex(6)> ExW3.Contract.register(:SimpleStorage, abi: simple_storage_abi)
:ok
iex(7)> {:ok, address, tx_hash} = ExW3.Contract.deploy(:SimpleStorage, bin: ExW3.load_bin("test/examples/build/SimpleStorage.bin"), options: %{gas: 300_000, from: Enum.at(accounts, 0)})
{:ok, "0x22018c2bb98387a39e864cf784e76cb8971889a5",
 "0x4ea539048c01194476004ef69f407a10628bed64e88ee8f8b17b4d030d0e7cb7"}
iex(8)> ExW3.Contract.at(:SimpleStorage, address)
:ok
iex(9)> ExW3.Contract.call(:SimpleStorage, :get)
{:ok, 0}
iex(10)> ExW3.Contract.send(:SimpleStorage, :set, [1], %{from: Enum.at(accounts, 0), gas: 50_000})
{:ok, "0x88838e84a401a1d6162290a1a765507c4a83f5e050658a83992a912f42149ca5"}
iex(11)> ExW3.Contract.call(:SimpleStorage, :get)
{:ok, 1}
```

## Asynchronous

ExW3 now provides async versions of `call` and `send`. They both return a `Task` that can be awaited on.

```elixir
  t = ExW3.Contract.call_async(:SimpleStorage, :get)
  {:ok, data} = Task.await(t)
```

## Listening for Events

Elixir doesn't have event listeners like say JS. However, we can simulate that behavior with message passing.
The way ExW3 handles event filters is with a background process that calls eth_getFilterChanges every cycle.
Whenever a change is detected it will send a message to whichever process is listening.

```elixir
# Start the background listener
ExW3.EventListener.start_link

# Assuming we have already registered our contract called :EventTester
# We can then add a filter for the event listener to look out for by passing in the event name, and the process we want to receive the messages when an event is triggered.
# For now we are going to use the main process, however, we could pass in a pid of a different process.
# We can also optionally specify extra parameters like `:fromBlock`, and `:toBlock`

filter_id = ExW3.Contract.filter(:EventTester, "Simple", self(), %{fromBlock: 42, toBlock: "latest"})

# We can then wait for the event. Using the typical receive keyword we wait for the first instance of the event, and then continue with the rest of the code. This is useful for testing.
receive do
  {:event, {filter_id, data}} -> IO.inspect data
end

# We can then uninstall the filter after we are done using it
ExW3.uninstall_filter(filter_id)

# ExW3 also provides a helper method to continuously listen for events, with the `listen` method.
# One use is to combine all of our filters with pattern matching
ExW3.EventListener.listen(fn result ->
  case result do
    {filter_id, data} -> IO.inspect data
    {filter_id2, data} -> IO.inspect data
  end
end

# The listen method is a simple receive loop waiting for `{:event, _}` messages.
# It looks like this:
def listen(callback) do
  receive do
    {:event, result} -> apply callback, [result]
  end
  listen(callback)
end

# You could do something similar with your own process, whether it is a simple Task or a more involved GenServer.
```

## Listening for Indexed Events

Ethereum allows for filtering events specific to its parameters using indexing. For all of the options see [here](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_newfilter)

If you have written your event in Solidity like this:
```
    event SimpleIndex(uint256 indexed num, bytes32 indexed data, uint256 otherNum);
```

You can add filter on which logs will be returned back to the RPC client, based on the indexed fields. ExW3 allows for 2 ways of specifying these parameters or `topics` in two ways. The first, and probably more preferred way, is with a map:

```elixir
  indexed_filter_id = ExW3.Contract.filter(
    :EventTester,
    "SimpleIndex",
    self(),
    %{
      topics: %{num: 46, data: "Hello, World!"},
    }
  )
```

The other option is with a list, but this is order dependent, and any values you don't want to specify must be represented with a `nil`.

```elixir
  indexed_filter_id = ExW3.Contract.filter(
    :EventTester,
    "SimpleIndex",
    self(),
    %{
      topics: [nil, "Hello, World!"]
    }
  )
```

In this case we are skipping the `num` topic, and only filtering on the `data` parameter.


# Compiling Solidity

To compile the test solidity contracts after making a change run this command:
```
solc --abi --bin --overwrite -o test/examples/build test/examples/contracts/*.sol
```