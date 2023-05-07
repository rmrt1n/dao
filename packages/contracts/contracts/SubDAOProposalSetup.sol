// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/// @dev Imports start here
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
import {PluginSetup, IPluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {SubDAOProposal} from "./SubDAOProposal.sol";
import {PluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {MajorityVotingBase} from "@aragon/osx/plugins/governance/majority-voting/MajorityVotingBase.sol";

/// @title SubDAOProposal
/// @author ClubDAO
/// @notice This plugin is used to manage the process of creating proposals, voting on proposals, and managing proposal status
/// @dev This plugin is paired with a setup contract that will take care of assigning relevant permissions to the special SubDAO parent
contract SubDAOProposalVotingSetup is PluginSetup {
    /// @notice The address of `AddresslistVoting` plugin logic contract to be used in creating proxy contracts.
    SubDAOProposal private immutable subDAOProposalBase;

    /// @notice The contract constructor, that deploys the `AddresslistVoting` plugin logic contract.
    constructor() {
        subDAOProposalBase = new SubDAOProposal();
    }

    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes calldata _data
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        // Decode `_data` to extract the params needed for deploying and initializing `AddresslistVoting` plugin.
        (
            MajorityVotingBase.VotingSettings memory votingSettings,
            SubDAOProposal.ParentDAO memory parentDAO
        ) = abi.decode(
                _data,
                (MajorityVotingBase.VotingSettings, SubDAOProposal.ParentDAO)
            );

        // Prepare and Deploy the plugin proxy.
        plugin = createERC1967Proxy(
            address(subDAOProposalBase),
            abi.encodeWithSelector(
                subDAOProposalBase.initialize.selector,
                _dao,
                votingSettings,
                parentDAO
            )
        );

        // Prepare permissions
        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](2);

        // Set permissions to be granted.
        // Grant the list of permissions of the plugin to the DAO.
        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            subDAOProposalBase.UPDATE_ADDRESSES_PERMISSION_ID()
        );

        // Grant `EXECUTE_PERMISSION` of the DAO to the plugin.
        permissions[1] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            _dao,
            plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        view
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](2);

        // Set permissions to be Revoked.
        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            subDAOProposalBase.UPDATE_ADDRESSES_PERMISSION_ID()
        );

        permissions[1] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _dao,
            _payload.plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );
    }

    /// @inheritdoc IPluginSetup
    function implementation() external view returns (address) {
        return address(subDAOProposalBase);
    }
}
