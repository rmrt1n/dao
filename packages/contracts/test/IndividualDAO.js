const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("IndividualDAO", async function () {
  async function deployTokenFixture() {
    encodeRawKey = (rawKey) => {
      return ethers.utils.keccak256(ethers.utils.toUtf8Bytes(rawKey));
    };

    // get the 8th account from the hardhat node
    const [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8] =
      await ethers.getSigners();

    const daoFactoryAddress = "0x3ff1681f31f68Ff2723d25Cf839bA7500FE5d218";
    const attestationStationAddress =
      "0x1a1f1720A3a4CF7E1DE28434672e6b61643a943D";
    const confirmDaoCreation = "confirm.dao.creation";
    const minAttestations = 1;

    const IndividualDAO = await ethers.getContractFactory("IndividualDAO");

    const individualDAO = await IndividualDAO.connect(addr8).deploy(
      daoFactoryAddress,
      attestationStationAddress,
      minAttestations,
      confirmDaoCreation
    );

    await individualDAO.deployed();

    //get the abi and connect to the proxy
    const AttestationStation = await ethers.getContractFactory(
      "AttestationStation"
    );

    const attestationProxy = AttestationStation.attach(
      attestationStationAddress
    );

    const confirmDAOCreationKey = encodeRawKey(confirmDaoCreation);

    //val 1 should be in bytes
    val = ethers.utils.formatBytes32String("1");

    return {
      individualDAO,
      owner,
      addr1,
      addr2,
      addr3,
      addr6,
      addr8,
      confirmDAOCreationKey,
      val,
      attestationStationAddress,
      daoFactoryAddress,
      confirmDaoCreation,
      minAttestations,
      attestationProxy,
    };
  }

  // describe("Deployment", function () {
  //   //We first check that the contract can deploy
  //   it("Should deploy the contract", async function () {
  //     const { individualDAO } = await loadFixture(deployTokenFixture);

  //     expect(individualDAO.address).to.properAddress;
  //   });
  // });

  // describe("Attestation", function () {
  //   //check that attestations can be created by anyone
  //   describe("Attestation Station Address", function () {
  //     //we first create attestations individually
  //     it("Should set the correct attestation station address", async function () {
  //       const { individualDAO, attestationStationAddress } = await loadFixture(
  //         deployTokenFixture
  //       );

  //       expect(await individualDAO.attestationStationContract()).to.equal(
  //         attestationStationAddress
  //       );
  //     });

  //     //it should only allow the deployer to change the attestation station address
  //     it("Should not allow anyone to change the attestation station address", async function () {
  //       const { individualDAO, addr1, owner } = await loadFixture(
  //         deployTokenFixture
  //       );

  //       await expect(
  //         individualDAO.connect(addr1).setAttestationStation(addr1.address)
  //       ).to.throw;
  //     });

  //     //it should allow the deployer to change the attestation station address
  //     it("Should allow the deployer to change the attestation station address", async function () {
  //       const { individualDAO, addr1, owner } = await loadFixture(
  //         deployTokenFixture
  //       );

  //       await individualDAO.setAttestationStation(addr1.address);

  //       expect(await individualDAO.attestationStationContract()).to.equal(
  //         addr1.address
  //       );
  //     });
  //   });

  //   describe("Minimum Attestations", function () {
  //     //we first create attestations individually
  //     it("Should set the correct number of minimum attestations", async function () {
  //       const { individualDAO, minAttestations } = await loadFixture(
  //         deployTokenFixture
  //       );

  //       expect(await individualDAO.minAttestations()).to.equal(minAttestations);
  //     });

  //     //it should only allow the deployer to change the attestation station address
  //     it("Should not allow anyone to change the minimum attestations", async function () {
  //       const { individualDAO, addr1 } = await loadFixture(deployTokenFixture);

  //       await expect(individualDAO.connect(addr1).setMinAttestations(2)).to
  //         .throw;
  //     });

  //     //it should allow the deployer to change the attestation station address
  //     it("Should allow the deployer to change the minimum attestations", async function () {
  //       const { individualDAO } = await loadFixture(deployTokenFixture);

  //       await individualDAO.setMinAttestations(2);

  //       expect(await individualDAO.minAttestations()).to.equal(2);
  //     });
  //   });

  //   describe("DAO Creation Key", function () {
  //     //we first create attestations individually
  //     it("Should set the correct dao creation key", async function () {
  //       const { individualDAO, confirmDAOCreationKey } = await loadFixture(
  //         deployTokenFixture
  //       );

  //       //the key is in keccak256(bytes(key)) format
  //       expect(await individualDAO.confirmDAOCreationKey()).to.equal(
  //         confirmDAOCreationKey
  //       );
  //     });

  //     //it should only allow the deployer to change the attestation station address
  //     it("Should not allow anyone to change the dao creation key", async function () {
  //       const { individualDAO, addr1 } = await loadFixture(deployTokenFixture);

  //       await expect(
  //         individualDAO.connect(addr1).setConfirmDAOCreationKey("test")
  //       ).to.throw;
  //     });

  //     //it should allow the deployer to change the attestation station address
  //     it("Should allow the deployer to change the dao creation key", async function () {
  //       const { individualDAO } = await loadFixture(deployTokenFixture);

  //       await individualDAO.setConfirmDAOCreationKey("test");

  //       expect(await individualDAO.confirmDAOCreationKey()).to.equal(
  //         encodeRawKey("test")
  //       );
  //     });
  //   });
  // });

  // describe("DAO Factory", function () {
  //   //check that attestations can be created by anyone
  //   describe("DAO Factory Address", function () {
  //     //we first make sure that the dao factory address is set correctly
  //     it("Should set the correct dao factory address", async function () {
  //       const { individualDAO, daoFactoryAddress } = await loadFixture(
  //         deployTokenFixture
  //       );

  //       expect(await individualDAO.daoFactory()).to.equal(daoFactoryAddress);
  //     });

  //     //it should only allow the deployer to change the dao factory address
  //     it("Should not allow anyone to change the dao factory address", async function () {
  //       const { individualDAO, addr1 } = await loadFixture(deployTokenFixture);

  //       await expect(individualDAO.connect(addr1).setDAOFactory(addr1.address))
  //         .to.throw;
  //     });

  //     //it should allow the deployer to change the dao factory address
  //     it("Should allow the deployer to change the dao factory address", async function () {
  //       const { individualDAO, addr1 } = await loadFixture(deployTokenFixture);

  //       await individualDAO.setDAOFactory(addr1.address);

  //       expect(await individualDAO.daoFactory()).to.equal(addr1.address);
  //     });
  //   });
  // });

  // describe("Setup Ref", function () {
  //   it("should return setup ref", async function () {
  //     const { individualDAO, addr1 } = await loadFixture(deployTokenFixture);

  //     const setupRef = await individualDAO.getSetupRef(
  //       "0x0DF9b15550fF39149e491dDD154b28f587e0cD16"
  //     );
  //   });
  // });

  // describe("Encoded Setup Data", function () {
  //   it("should return encoded setup data", async function () {
  //     const { individualDAO } = await loadFixture(deployTokenFixture);

  //     const encodedSetupData = await individualDAO.getEncodedSetupData(
  //       "0x0DF9b15550fF39149e491dDD154b28f587e0cD16"
  //     );

  //     console.log("encoded setup data: ", encodedSetupData);
  //   });
  // });

  describe("Create DAO", function () {
    it("should check if the initial DAO members have attested", async function () {
      const {
        individualDAO,
        owner,
        addr1,
        addr2,
        addr3,
        addr6,
        addr8,
        confirmDAOCreationKey,
        attestationProxy,
      } = await loadFixture(deployTokenFixture);

      await individualDAO.setMinAttestations(1);

      // pre create a message hash to be sent to the signer
      msgHashAddr2 = ethers.utils.solidityKeccak256(
        ["address", "bytes32", "bytes"],
        [addr1.address, confirmDAOCreationKey, val]
      );

      signerAddr2 = await ethers.getSigner(addr8.address);

      sigAddr2 = await signerAddr2.signMessage(
        ethers.utils.arrayify(msgHashAddr2)
      );

      console.log("addr6:", addr8.address);
      console.log("addr1", addr1.address);
      console.log("confirmkey", confirmDAOCreationKey);
      console.log("val", val);
      console.log("sign", sigAddr2);

      // await expect(
      //   individualDAO.createDAO(
      //     [addr1.address, addr2.address],
      //     "0x0DF9b15550fF39149e491dDD154b28f587e0cD16",
      //     { gasLimit: 5000000 }
      //   )
      // ).to.be.revertedWith("Not enough attestations");
      const dao = await individualDAO
        .connect(addr8) //the address that is setting up the DAO, the address that should be attested for
        .createDAO(
          [addr1.address],
          "0x0DF9b15550fF39149e491dDD154b28f587e0cD16",
          { gasLimit: 9999999 }
        );

      console.log("dao: ", dao);
    });
  });
});
