# Install Rust for ex_keccack NIF
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# Install parity blockchain for testing
echo > passfile # just to be safe

wget https://releases.parity.io/ethereum/v1.8.5/x86_64-unknown-linux-gnu/parity

chmod 755 ./parity
echo > passfile

./parity --chain dev 2>&1 &

PARITY_PID=$!
sleep 10
kill -9 $(lsof -t -i:8545) # cleanup old zombie instances
