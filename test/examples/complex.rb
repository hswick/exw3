require './lib/w3'

url = "http://localhost:8545"
http_client = W3::Http_Client.new(url)

eth = W3::ETH.new(http_client)

accounts = eth.get_accounts

abi = JSON.parse(File.read(File.join(File.dirname(__FILE__), './build/Complex.abi')))
complex = W3::Contract.new(eth, abi)

bin =  File.read(File.join(File.dirname(__FILE__), './build/Complex.bin'))
complex.at! complex.deploy!(bin, {"from" => accounts[0], "gas" => 300000}, 6, "foo")

pp complex.address

pp complex.get_both

# complex.set_bar_foo! true, {"from" => accounts[0]}
# pp complex.get_bar_foo

# pp complex.get_foo_boo 66

# pp complex.get_bro_and_bro_bro