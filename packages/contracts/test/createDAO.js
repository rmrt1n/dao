const { expect } = require("chai");
const {
  DAOFactory__factory,
  DAORegistry__factory,
  PluginRepo__factory,
  activeContractsList,
} = require("@aragon/osx-ethers");
const dotenv = require("dotenv");
dotenv.config();

describe("Deploy DAO script", () => {
  it("should deploy a DAO with a token voting app", async () => {
    const BN = ethers.BigNumber.from;
    const ZeroAddress = `0x${"00".repeat(20)}`;

    const DEVNET_RPC =
      "https://rpc.vnet.tenderly.co/devnet/defaf85a-5fc8-45b6-9811-b54fd8af9fe4/bea8de79-145e-4f57-a6ba-6e633e339329";
    const { KNOWN_PRIVATE_KEY } = process.env;

    const provider = ethers.getDefaultProvider(DEVNET_RPC);
    const wallet = new ethers.Wallet(KNOWN_PRIVATE_KEY, provider);

    // 1. get the token voting repo. we need this to get the latest version
    // of the token voting app and as well as initialize data
    const tokenVotingRepo = PluginRepo__factory.connect(
      activeContractsList.mumbai["admin-repo"],
      wallet
    );
    const latestVersion = await tokenVotingRepo["getLatestVersion(uint8)"](
      await tokenVotingRepo.latestRelease()
    );
    console.log("latestVersion", latestVersion);

    // this points to the current version of the token voting app in the token voting repo
    const setupRef = {
      pluginSetupRepo: tokenVotingRepo.address,
      versionTag: latestVersion.tag,
    };

    // 3. encode the setup data. this is very low level, you're better off using the SDK to do this but as
    // a plugin dev you should understand what's happening under the hood. especially as you need to write
    // your own setup data for your plugin. Most plugins will not have so many params though.
    // https://github.com/aragon/osx/blob/527474bb14529f2892e8277f6d7a1ca2da637a55/packages
    const abiCoder = new ethers.utils.AbiCoder();
    const encodedSetupData = abiCoder.encode(
      ["address"], // it only takes one parameter, the admin address
      ["0xA4fdc61C4678aDe105aF1F2b3292428332c000B0"] // he address of the admin
    );

    //define a sample function
    function hexToBytes(hexString) {
      if (!hexString) {
        return new Uint8Array();
      } else if (!/^(0x)?[0-9a-fA-F]*$/.test(hexString)) {
        throw new Error("Invalid hex string");
      } else if (hexString.length % 2 !== 0) {
        throw new Error("The hex string has an odd length");
      }

      hexString = strip0x(hexString);
      const bytes = [];
      for (let i = 0; i < hexString.length; i += 2) {
        bytes.push(parseInt(hexString.substring(i, i + 2), 16));
      }
      return Uint8Array.from(bytes);
    }

    function strip0x(value) {
      return value.startsWith("0x") ? value.substring(2) : value;
    }

    const installData = {
      pluginSetupRef: setupRef,
      data: hexToBytes(encodedSetupData),
    };

    // 4. create the DAO
    const daoFactory = DAOFactory__factory.connect(
      activeContractsList.mumbai.DAOFactory,
      wallet
    );

    const daoCreationTx = await daoFactory.createDao(
      {
        metadata: ethers.utils.toUtf8Bytes("ipfs://Qm..."),
        subdomain: `some-dao-w${Math.floor(Math.random() * 1000)}`,
        daoURI: "https://daobox.app",
        trustedForwarder: `0x${"00".repeat(20)}`,
      },
      [installData],
      { gasLimit: 5000000 }
    );

    // 5. wait for the DAO to be created
    const daoReceipt = await daoCreationTx.wait();
    const daoInterface = DAORegistry__factory.createInterface();
    const daoTopic = daoInterface.getEventTopic("DAORegistered");
    const daoLog = daoReceipt.logs.find((x) => x.topics.indexOf(daoTopic) >= 0);
    if (!daoLog) throw new Error("UH OH");
    const daoAddress = daoInterface.parseLog(daoLog).args.dao;

    // 6. assert that the DAO was created successfully
    expect(daoAddress).to.be.a("string");
    expect(daoAddress).to.have.lengthOf(42);
    expect(daoAddress).to.match(/^0x[0-9a-fA-F]+$/);
  });
});
