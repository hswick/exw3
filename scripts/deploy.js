const fs = require('fs');
const path = require('path');

// write down contracts that you wish to deploy one-by-one (names only, no .sol extension)
// after the run, find the ABIs and addresses in frontend/src/contracts
const contracts = ["MyCollectibleErc721", "AddressTester", "ArrayTester", "Complex", "EventTester", "SimpleStorage"];

// DO NOT MODIFY CODE BELOW UNLESS ABSOLUTELY NECESSARY
async function publishContract(contractName, chainId) {
  // deploy the contract
  const contractFactory = await ethers.getContractFactory(contractName);
  const contract = contractName == "Complex" ? await contractFactory.deploy(10, "0x6d6168616d000000000000000000000000000000000000000000000000000000") : await contractFactory.deploy();

  console.log(contractName + " contract address: " + contract.address);

  // copy the contract JSON file to front-end and add the address field in it
  fs.copyFileSync(
    path.join(__dirname, "../test/examples/build/test/examples/contracts/" + contractName + ".sol/" + contractName + ".json"), //source
    path.join(__dirname, "../test/examples/build/" + contractName + ".json") // destination
  );

  // check if addresses.json already exists
  let exists = fs.existsSync(path.join(__dirname, "../test/examples/build/addresses.json"));

  // if not, created the file
  if (!exists) {
    fs.writeFileSync(
      path.join(__dirname, "../test/examples/build/addresses.json"),
      "{}"
    );
  }

  // update the addresses.json file with the new contract address
  let addressesFile = fs.readFileSync(path.join(__dirname, "../test/examples/build/addresses.json"));
  let addressesJson = JSON.parse(addressesFile);

  if (!addressesJson[contractName]) {
    addressesJson[contractName] = {};
  }

  addressesJson[contractName][chainId] = contract.address;

  fs.writeFileSync(
    path.join(__dirname, "../test/examples/build/addresses.json"),
    JSON.stringify(addressesJson)
  );
}

async function main() {
  const [deployer] = await ethers.getSigners();

  let networkData = await deployer.provider.getNetwork()
  console.log("Chain ID:", networkData.chainId);

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  for (cont of contracts) {
    await publishContract(cont, networkData.chainId);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });