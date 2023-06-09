require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");
require("dotenv").config();

encodeRawKey = (rawKey) => {
  if (rawKey.length < 32) {
    return ethers.utils.formatBytes32String(rawKey);
  }

  const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(rawKey));
  return hash.slice(0, 64) + "ff";
};

attestationProxyAddr = "0xd0dAd0622b848f3f290B3611A5d5610BFA81bE09";
attestationStationProxyAddr = "0xc2361C2Eb9fc7010f7FCb9F79d7bFAEEFE5CDAb2";

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("attestProxy", "Attest about an address through the proxy")
  .addOptionalParam(
    "fromAddress",
    "The address index to attest from (first account: 0, default: 5)",
    5,
    types.int
  )
  .addParam("forAddress", "The address to attest for")
  .addOptionalParam(
    "key",
    "The key to attest (default: confirm.account.recovery)",
    "confirm.account.recovery",
    types.string
  )
  .addOptionalParam(
    "value",
    "The value to attest (default: 1)",
    "1",
    types.string
  )
  .setAction(async (taskArgs, hre) => {
    AttestationProxy = await ethers.getContractFactory("AttestationProxy");
    attestationProxy = AttestationProxy.attach(attestationProxyAddr);
    //create the message hash
    msgHash = ethers.utils.solidityKeccak256(
      ["address", "bytes32", "bytes"],
      [
        taskArgs.forAddress,
        encodeRawKey(taskArgs.key),
        ethers.utils.toUtf8Bytes(taskArgs.value),
      ]
    );

    //get the signer
    const signers = await ethers.getSigners();
    signer = signers[taskArgs.fromAddress];

    console.log("Signing message hash: " + signer.address);

    //sign the message
    sig = await signer.signMessage(ethers.utils.arrayify(msgHash));

    //send the transaction
    tx = await attestationProxy
      .connect(signer)
      .attest(
        taskArgs.forAddress,
        encodeRawKey(taskArgs.key),
        ethers.utils.toUtf8Bytes(taskArgs.value),
        sig
      );
    rcpt = await tx.wait();
    console.log(rcpt);
  });

task("checkAttest", "Check the attestation made")
  .addOptionalParam(
    "fromAddress",
    "The address index to attest from",
    8,
    types.int
  )
  .addParam("forAddress", "The address attested for")
  .addOptionalParam(
    "key",
    "The key to attest (default: confirm.account.recovery)",
    "confirm.account.recovery",
    types.string
  )
  .setAction(async (taskArgs, hre) => {
    AttestationStation = await ethers.getContractFactory("AttestationStation");
    attestationStationProxy = AttestationStation.attach(
      attestationStationProxyAddr
    );

    //get the signer
    const signers = await ethers.getSigners();
    signer = signers[taskArgs.fromAddress];

    console.log(
      (await attestationStationProxy
        .connect(signer)
        .attestations(
          signer.address,
          taskArgs.forAddress,
          encodeRawKey(taskArgs.key)
        )) != "0x"
    );
  });

task(
  "checkAllAttestations",
  "Checks all attestations for an address attested for"
)
  .addParam("forAddress", "The address attested for")
  .setAction(async (taskArgs, hre) => {
    AttestationStation = await ethers.getContractFactory("AttestationStation");
    attestationStationProxy = AttestationStation.attach(
      attestationStationProxyAddr
    );
    aboutAddr = attestationStationProxy.filters.AttestationCreated(
      null,
      taskArgs.forAddress,
      null,
      null
    );

    events = await attestationStationProxy.queryFilter(aboutAddr);
    console.log(events);
  });

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const words = process.env.MNEMONIC.match(/[a-zA-Z]+/g).length;
validLength = [12, 15, 18, 24];
if (!validLength.includes(words)) {
  console.log(
    `The mnemonic (${process.env.MNEMONIC}) is the wrong number of words`
  );
  process.exit(-1);
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY,
      optimisticGoerli: process.env.OPTIMISTIC_GOERLI_API_KEY,
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      optimisticEthereum: process.env.OPTIMISTIC_GOERLI_API_KEY,
      polygon: process.env.POLYGONSCAN_API_KEY,
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 999999999,
      },
    },
    networks: {
      "local-devnode": {
        url: "http://localhost:8545",
        accounts: {
          mnemonic: process.env.MNEMONIC,
        },
      },
      optimismGoerli: {
        url: process.env.ALCHEMY_API_KEY_OPTIMISM_GOERLI
          ? `https://opt-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_OPTIMISM_GOERLI}`
          : process.env.OPTIMISM_GOERLI_URL,
        accounts: {
          mnemonic: process.env.MNEMONIC,
        },
      },
      ethSepolia: {
        url: process.env.ALCHEMY_API_KEY_SEPOLIA
          ? `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_SEPOLIA}`
          : process.env.ETH_SEPOLIA_URL,
        accounts: {
          mnemonic: process.env.MNEMONIC,
        },
      },
      polygonMumbai: {
        url: process.env.ALCHEMY_API_KEY_POLYGON_MUMBAI
          ? `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_POLYGON_MUMBAI}`
          : process.env.POLYGON_MUMBAI_URL,
        accounts: {
          mnemonic: process.env.MNEMONIC,
        },
      },
      hardhat: {
        forking: {
          url: process.env.ALCHEMY_API_KEY_POLYGON_MUMBAI
            ? `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_POLYGON_MUMBAI}`
            : process.env.ETH_SEPOLIA_URL,
        },
        accounts: {
          mnemonic: process.env.MNEMONIC,
        },
      },
      polygon: {
        url: process.env.ALCHEMY_API_KEY_POLYGON
          ? `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_POLYGON}`
          : process.env.ETH_SEPOLIA_URL,
        accounts: {
          mnemonic: process.env.MNEMONIC,
        },
      },
      devnet: {
        url: "https://rpc.vnet.tenderly.co/devnet/defaf85a-5fc8-45b6-9811-b54fd8af9fe4/bea8de79-145e-4f57-a6ba-6e633e339329",
        accounts: {
          mnemonic: process.env.MNEMONIC,
        },
      },
    },
    namedAccounts: {
      deployer: {
        default: 6,
        ethSepolia: 6,
        optimismGoerli: 8,
        scrollAlpha: 8,
        polygonMumbai: 8,
        optimism: 6,
        polygon: 6,
        devnet: 8,
      },
    },
    mocha: {
      timeout: 200000,
    },
  },
};
