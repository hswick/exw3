
#!/bin/bash

# This is for travis
parity --chain dev --unlock=0x00a329c0648769a73afac7f9381e08fb43dbea72 --reseal-min-period 0 --password passfile 2>&1 &
sleep 10
mix test
sleep 10
kill -9 $(lsof -t -i:8545)
