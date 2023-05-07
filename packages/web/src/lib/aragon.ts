import { Wallet } from "@ethersproject/wallet";
import { Context, ContextParams } from "@aragon/sdk-client";

// Set up your IPFS API key. You can get one either by running a local node or by using a service like Infura or Alechmy.
// Make sure to always keep these private in a file that is not committed to your public repository.
export const IPFS_API_KEY: string = "ipfs-api-key";

export const contextParams: ContextParams = {
  // Choose the network you want to use. You can use "goerli" or "mumbai" for testing, "mainnet" for Ethereum.
  network: "goerli",
  // Depending on how you're configuring your wallet, you may want to pass in a `signer` object here.
  signer: new Wallet("private-key"),
  // Optional on "rinkeby", "arbitrum-rinkeby" or "mumbai"
  // Pass the address of the  `DaoFactory` contract you want to use. You can find it here based on your chain of choice: https://github.com/aragon/core/blob/develop/active_contracts.json
  daoFactoryAddress: "0x1234381072385710239847120734123847123",
  // Choose your Web3 provider: Cloudfare, Infura, Alchemy, etc.
  web3Providers: ["https://rpc.ankr.com/eth_goerli"],
  ipfsNodes: [
    {
      url: "https://testing-ipfs-0.aragon.network/api/v0",
      headers: { "X-API-KEY": IPFS_API_KEY || "" }
    },
  ],
  // Don't change this line. This is how we connect your app to the Aragon subgraph.
  graphqlNodes: [
    {
      url:
        "https://subgraph.satsuma-prod.com/aragon/core-goerli/api"
    }
  ]
};

// Instantiate the Aragon SDK context
export const context: Context = new Context(contextParams);
