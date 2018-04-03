require './lib/w3'

url = "http://localhost:8545"
http_client = W3::Http_Client.new(url)

eth = W3::ETH.new(http_client)

accounts = eth.get_accounts
pp accounts

puts "Block number: #{eth.get_block_number}"

abi = JSON.parse(File.read(File.join(File.dirname(__FILE__), './build/ArrayTester.abi')))
array_tester = W3::Contract.new(eth, abi)

bin =  File.read(File.join(File.dirname(__FILE__), './build/ArrayTester.bin'))
array_tester.at! array_tester.deploy!(bin, {"from" => accounts[0], "gas" => 300000})

pp array_tester.dynamic_uint([1, 2, 3, 4, 5,])

#pp array_tester.static_uint([1, 2, 3, 4, 5,])