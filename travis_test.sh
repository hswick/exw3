
#!/bin/bash

# This is for travis
ganache-cli 2>&1 &
sleep 10
mix test
sleep 10
kill -9 $(lsof -t -i:8545)