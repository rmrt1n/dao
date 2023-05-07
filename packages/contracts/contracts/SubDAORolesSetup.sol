// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/// @dev Imports start here
import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
import {PluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {SubDAORoles} from "./SubDAORoles.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";

/// @title SubDAO Roles Setup
/// @author ClubDAO
/// @notice This plugin is used to assign special roles to specific members of the new DAO using proposal details and the hats protocol
/// @dev This plugin is paired with a setup contract that will take care of assigning relevant permissions to the special SubDAO parent
contract SubDAORolesSetup is PluginSetup {
    /// @notice The address of the `Sub DAO Roles` plugin logic contract to be cloned.
    address private immutable implementation_;

    using Clones for address;

    /// @notice The constructor setting the `SimpleAdmin` implementation contract to clone from.
    constructor() {
        implementation_ = address(new SubDAORoles());
    }

    function implementation() external view returns (address) {
        return implementation_;
    }

    function prepareInstallation(
        address _dao,
        bytes calldata _data
    )
        external
        override
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        // Decode `_data` to extract the params needed for cloning and initializing `Sub DAO Roles` plugin. There are four parameters used to initalize the plugin
        (
            address hatsProtocol,
            address targetDAO,
            string memory details,
            string memory imageURI
        ) = abi.decode(_data, (address, address, string, string));

        plugin = implementation_.clone();

        // Initialize cloned plugin contract.
        SubDAORoles(plugin).initialize(
            IDAO(_dao),
            hatsProtocol,
            targetDAO,
            details,
            imageURI
        );

        // Prepare permissions
        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](2);

        // Grant `ADMIN_EXECUTE_PERMISSION` of the plugin to the admin.
        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            SubDAORoles(plugin).ROLE_ASSIGN_PERMISSION_ID()
        );

        // Grant `EXECUTE_PERMISSION` on the DAO to the plugin.
        permissions[1] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            _dao,
            plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );

        preparedSetupData.permissions = permissions;
    }

    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        view
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _dao,
            _payload.plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );
    }
}
