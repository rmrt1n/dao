// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import "@aragon/osx/framework/dao/DAOFactory.sol";
import "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";

import "./AttestationStation.sol";

// Only the owner can change the constructor parameters
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title IndividualDAO
/// @notice Custom DAOFactory for creating individual DAOs with selected plugins.
contract IndividualDAO is Ownable {
    DAOFactory public daoFactory;
    PluginRepo public pluginRepo;
    PluginSetupRef public pluginSetupRef;
    AttestationStation public attestationStationContract;
    uint256 public minAttestations;
    bytes32 public confirmDAOCreationKey;

    event LatestRelease(uint8 latestRelease);

    event Version(PluginRepo.Version version);

    //event to see the plugin setup repo
    event PluginSetupRepo(PluginRepo pluginSetupRepo);

    struct setupRef {
        address _tokenVotingRepo;
        PluginRepo.Tag _versionTag;
    }

    error AddressDidNotAttest(address _address);

    error NotEnoughAttestations(uint256 _numAttestations);

    /// @param _daoFactory The address of the DAOFactory contract deployed on the network.
    constructor(
        address _daoFactory,
        address _attestationStationProxy,
        uint256 _minAttestations,
        string memory _confirmDAOCreationKey
    ) {
        daoFactory = DAOFactory(_daoFactory);
        console.log("daoFactory: %s", _daoFactory);
        attestationStationContract = AttestationStation(
            _attestationStationProxy
        );
        minAttestations = _minAttestations;
        confirmDAOCreationKey = keccak256(bytes(_confirmDAOCreationKey));
    }

    //the modifier accepts an array of addresses, the salt used to get the DAO address, and the recovery key
    modifier _isDAOAttested(address[] memory _initialDAOMembers) {
        //if the length of the initial members is less than the min attestations, revert
        if (_initialDAOMembers.length < minAttestations) {
            revert NotEnoughAttestations(_initialDAOMembers.length);
        }
        _;

        for (uint256 i = 0; i < _initialDAOMembers.length; i++) {
            //check if the address is attested
            uint confirm = 1;
            bytes memory confirmBytes = abi.encodePacked(confirm);
            bytes memory _val = attestationStationContract.attestations(
                _initialDAOMembers[i],
                msg.sender,
                confirmDAOCreationKey
            );
            if (
                keccak256(abi.encodePacked(_val)) !=
                keccak256(abi.encodePacked(confirmBytes))
            ) {
                console.log("address did not attest");
                revert AddressDidNotAttest(_initialDAOMembers[i]);
            }
            _;
        }
    }

    function setAttestationStation(
        address _attestationStation
    ) external onlyOwner {
        attestationStationContract = AttestationStation(_attestationStation);
    }

    function setMinAttestations(uint256 _minAttestations) external onlyOwner {
        console.log("min attestations: %s", _minAttestations);
        minAttestations = _minAttestations;
    }

    function setDAOFactory(address _daoFactoryAddress) external onlyOwner {
        daoFactory = DAOFactory(_daoFactoryAddress);
    }

    function setConfirmDAOCreationKey(
        string memory _confirmDAOCreationKey
    ) external onlyOwner {
        confirmDAOCreationKey = keccak256(bytes(_confirmDAOCreationKey));
    }

    function getLatestVersion(uint8 _release, address _pluginRepo) public {
        pluginRepo = PluginRepo(_pluginRepo);

        //now get the latest release
        uint8 latestRelease = pluginRepo.latestRelease();
        console.log("latest release: %s", latestRelease);
    }

    //we will first try to connect to the admin repo using the PluginRepoFactory
    function getSetupRef(
        address _pluginRepo
    ) public returns (PluginSetupRef memory) {
        console.log("im called");
        console.log("plugin repo: %s", _pluginRepo);
        //first connect to the intended plugin repo, e.g. token-voting-repo
        //use proxy address when connecting to the repo
        pluginRepo = PluginRepo(_pluginRepo);

        //now get the latest release
        uint8 latestRelease = pluginRepo.latestRelease();
        console.log("latest release: %s", latestRelease);

        //then get the latest version tag,return value is a tuple
        PluginRepo.Version memory version = pluginRepo.getLatestVersion(
            latestRelease
        );

        // this is points to the current version of the token voting app in the token voting repo
        PluginSetupRef memory currentSetupRef = PluginSetupRef({
            versionTag: version.tag,
            pluginSetupRepo: pluginRepo
        });

        //return the setupRef
        return currentSetupRef;
    }

    function getEncodedSetupData(
        address _pluginRepo
    ) public returns (DAOFactory.PluginSettings memory) {
        bytes memory encodedSetupData = abi.encode(
            address(0x8dC75164dab325Dda81022cE7ee7a2B23a207C04)
        );

        //now get the encoded setup data
        DAOFactory.PluginSettings memory pluginSettings = DAOFactory
            .PluginSettings({
                pluginSetupRef: getSetupRef(_pluginRepo),
                data: encodedSetupData
            });

        return pluginSettings;
    }

    function createDAO(
        address[] memory _initialDAOMembers,
        address _pluginRepo
    ) public {
        DAOFactory.PluginSettings[]
            memory pluginSettings = new DAOFactory.PluginSettings[](1);

        //instantiate the DAOSettings struct
        DAOFactory.DAOSettings memory daoSettings = DAOFactory.DAOSettings({
            trustedForwarder: address(0),
            daoURI: "",
            subdomain: "",
            metadata: ""
        });

        //insert values in PluginSettings array
        DAOFactory.PluginSettings memory pluginSetting = getEncodedSetupData(
            _pluginRepo
        );

        pluginSettings[0] = pluginSetting;

        console.log("daobase:", daoFactory.daoBase());
        //create the DAO
        daoFactory.createDao(daoSettings, pluginSettings);
    }
}
