// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import "@aragon/osx/framework/dao/DAOFactory.sol";
import "./AttestationStation.sol";

// Only the owner can change the constructor parameters
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title IndividualDAO
/// @notice Custom DAOFactory for creating individual DAOs with selected plugins.
contract IndividualDAO is Ownable {
    DAOFactory public daoFactory;
    AttestationStation public attestationStationContract;
    uint256 public minAttestations;

    /// @param _daoFactoryAddress The address of the DAOFactory contract deployed on the network.
    constructor(
        address _daoFactoryAddress,
        address _attestationStationProxy,
        uint256 _minAttestations
    ) {
        daoFactory = DAOFactory(_daoFactoryAddress);
        attestationStationContract = AttestationStation(
            _attestationStationProxy
        );
        minAttestations = _minAttestations;
    }

    //the modifier accepts an array of addresses, the salt used to get the DAO address, and the recovery key
    modifier _isDAOAttested(
        address[] memory _recoveryAccounts,
        bytes32 _salt,
        bytes32 _recoveryKey
    ) {
        //get the DAO address from the salt
        address daoAddress = daoFactory.computeAddress(_salt);

        //use a for loop to check each address in the array, and only use require statement if any false is found
        for (uint256 i = 0; i < _recoveryAccounts.length; i++) {
            //check if the address is attested
            require(
                attestationStationContract.attestations(
                    _recoveryAccounts[i],
                    address(this),
                    _recoveryKey == 
                ),
                "Address not attested"
            );
        }
        _;
    }

    function setAttestationStation(
        address _attestationStation
    ) external onlyOwner {
        attestationStationContract = AttestationStation(_attestationStation);
    }

    function setMinAttestations(uint256 _minAttestations) external onlyOwner {
        minAttestations = _minAttestations;
    }

    function setDAOFactory(address _daoFactoryAddress) external onlyOwner {
        daoFactory = DAOFactory(_daoFactoryAddress);
    }

    /// @notice Creates a new DAO, registers it on the  DAO registry, and installs a list of plugins via the plugin setup processor.
    /// @param _daoSettings The DAO settings to be set during the DAO initialization.
    /// @param _pluginSettings The array containing references to plugins and their settings to be installed after the DAO has been created.
    // function createDao(
    //     DAOSettings calldata _daoSettings,
    //     PluginSettings[] calldata _pluginSettings
    // ) public override returns (DAO createdDao) {
    //     // Check if no plugin is provided.
    //     if (_pluginSettings.length == 0) {
    //         revert NoPluginProvided();
    //     }
    //     // Create DAO.
    //     createdDao = _createDAO(_daoSettings);
    //     // Register DAO.
    //     daoRegistry.register(createdDao, msg.sender, _daoSettings.subdomain);
    //     // Get Permission IDs
    //     bytes32 rootPermissionID = createdDao.ROOT_PERMISSION_ID();
    //     bytes32 applyInstallationPermissionID = pluginSetupProcessor
    //         .APPLY_INSTALLATION_PERMISSION_ID();
    //     // Grant the temporary permissions.
    //     // Grant Temporarly `ROOT_PERMISSION` to `pluginSetupProcessor`.
    //     createdDao.grant(
    //         address(createdDao),
    //         address(pluginSetupProcessor),
    //         rootPermissionID
    //     );
    //     // Grant Temporarly `APPLY_INSTALLATION_PERMISSION` on `pluginSetupProcessor` to this `DAOFactory`.
    //     createdDao.grant(
    //         address(pluginSetupProcessor),
    //         address(this),
    //         applyInstallationPermissionID
    //     );
    //     // Install plugins on the newly created DAO.
    //     for (uint256 i; i < _pluginSettings.length; ++i) {
    //         // Prepare plugin.
    //         (
    //             address plugin,
    //             IPluginSetup.PreparedSetupData memory preparedSetupData
    //         ) = pluginSetupProcessor.prepareInstallation(
    //                 address(createdDao),
    //                 PluginSetupProcessor.PrepareInstallationParams(
    //                     _pluginSettings[i].pluginSetupRef,
    //                     _pluginSettings[i].data
    //                 )
    //             );
    //         // Apply plugin.
    //         pluginSetupProcessor.applyInstallation(
    //             address(createdDao),
    //             PluginSetupProcessor.ApplyInstallationParams(
    //                 _pluginSettings[i].pluginSetupRef,
    //                 plugin,
    //                 preparedSetupData.permissions,
    //                 hashHelpers(preparedSetupData.helpers)
    //             )
    //         );
    //     }
    //     // Set the rest of DAO's permissions.
    //     _setDAOPermissions(createdDao);
    //     // Revoke the temporarly granted permissions.
    //     // Revoke Temporarly `ROOT_PERMISSION` from `pluginSetupProcessor`.
    //     createdDao.revoke(
    //         address(createdDao),
    //         address(pluginSetupProcessor),
    //         rootPermissionID
    //     );
    //     // Revoke `APPLY_INSTALLATION_PERMISSION` on `pluginSetupProcessor` from this `DAOFactory` .
    //     createdDao.revoke(
    //         address(pluginSetupProcessor),
    //         address(this),
    //         applyInstallationPermissionID
    //     );
    //     // Revoke Temporarly `ROOT_PERMISSION_ID` from `pluginSetupProcessor` that implecitly granted to this `DaoFactory`
    //     // at the create dao step `address(this)` being the initial owner of the new created DAO.
    //     createdDao.revoke(address(createdDao), address(this), rootPermissionID);
    // }
}
