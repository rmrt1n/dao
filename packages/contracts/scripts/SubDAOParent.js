const {
  DAOFactory__factory,
  DAORegistry__factory,
  PluginRepo__factory,
  activeContractsList,
} = require("@aragon/osx-ethers");
const { ethers } = require("ethers");

const RPC = `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_POLYGON_MUMBAI}`;
const provider = new ethers.providers.JsonRpcProvider(RPC);
const wallet = new ethers.Wallet(process.env.KNOWN_PRIVATE_KEY, provider);

console.log("wallet.address", wallet.address);

async function deployDAO() {
  const BN = ethers.BigNumber.from;
  const ZeroAddress = `0x${"00".repeat(20)}`;

  // 1. get the token voting repo. we need this to get the latest version
  // of the token voting app and as well as initialize data
  const adminRepo = PluginRepo__factory.connect(
    activeContractsList.mumbai["admin-repo"],
    wallet
  );
  const latestVersion = await adminRepo["getLatestVersion(uint8)"](
    await adminRepo.latestRelease()
  );
  console.log("latestVersion", latestVersion);

  // this points to the current version of the token voting app in the token voting repo
  const setupRef = {
    pluginSetupRepo: adminRepo.address,
    versionTag: latestVersion.tag,
  };

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
      metadata: ethers.utils.toUtf8Bytes("SubDAO Parent"),
      subdomain: `sub-dao-parent`,
      daoURI: "https://test.app.aragon.org/",
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
  console.log("DAO created with address:", daoAddress);
}

deployDAO();

//TODO: add a plugin for the subdao to retrieve proposals from the parent dao(s)
//If only 1 DAO wants to create the SubDAO, then the proposal should be created by a member of the parent DAO,
//and a majority vote is needed. Use token majority to calculate if proposal passes.
//If more than 1 DAO, majority should be on the basis that both DAOs have voted in favor of the proposal.
//If 1 DAO votes in favor and the other against, the proposal should fail.
