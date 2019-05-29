# just to be safe
echo > passfile


wget https://releases.parity.io/ethereum/v1.8.5/x86_64-unknown-linux-gnu/parity

chmod 755 ./parity
echo > passfile

./parity --chain dev 2>&1 &

PARITY_PID=$!
sleep 10
kill -9 $(lsof -t -i:8545)
