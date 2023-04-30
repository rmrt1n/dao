pragma solidity 0.8.17;

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

import {PermissionLib} from '@aragon/osx/core/permission/PermissionLib.sol';
import {PluginSetup, IPluginSetup} from '@aragon/osx/framework/plugin/setup/PluginSetup.sol';

import {nftGovernance} from './NFTGovernance.sol';
import {IDAO, DAO} from '@aragon/osx/core/dao/DAO.sol';

contract nfgGovernanceSetup is PluginSetup{
    using Clones for address;

    address private immutable nftGovernanceImplementation;

    constructor(){
        nftGovernanceImplementation = address(new nftGovernance());
    }

    function prepareInstallation(
        address _dao,
        bytes calldata _data
    ) external returns (address plugin, PreparedSetupData memory preparedSetupData) {
        // Decode `_data` to extract the params needed for cloning and initializing `Admin` plugin.
        address admin = abi.decode(_data, (address));

        // Clone plugin contract.
        plugin = nftGovernanceImplementation.clone();

        // Initialize cloned plugin contract.
        nftGovernance(plugin).initialize(IDAO(_dao), admin);

        // Prepare permissions
        PermissionLib.MultiTargetPermission[]
        memory permissions = new PermissionLib.MultiTargetPermission[](2);

        // Grant the `ADMIN_EXECUTE_PERMISSION` of the Plugin to the admin.
        permissions[0] = PermissionLib.MultiTargetPermission({
        operation: PermissionLib.Operation.Grant,
        where: plugin,
        who: admin,
        condition: PermissionLib.NO_CONDITION,
        permissionId: nftGovernance(plugin).ADMIN_EXECUTE_PERMISSION_ID()
        });

        // Grant the `EXECUTE_PERMISSION` on the DAO to the plugin.
        permissions[1] = PermissionLib.MultiTargetPermission({
        operation: PermissionLib.Operation.Grant,
        where: _dao,
        who: plugin,
        condition: PermissionLib.NO_CONDITION,
        permissionId: DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        });

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    ) external view returns (PermissionLib.MultiTargetPermission[] memory permissions) {
        // Collect addresses
        address plugin = _payload.plugin;
        address admin = nftGovernance(plugin).admin();

        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](2);

        permissions[0] = PermissionLib.MultiTargetPermission({
        operation: PermissionLib.Operation.Revoke,
        where: plugin,
        who: admin,
        condition: PermissionLib.NO_CONDITION,
        permissionId: nftGovernance(plugin).ADMIN_EXECUTE_PERMISSION_ID()
        });

        permissions[1] = PermissionLib.MultiTargetPermission({
        operation: PermissionLib.Operation.Revoke,
        where: _dao,
        who: plugin,
        condition: PermissionLib.NO_CONDITION,
        permissionId: DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        });
    }
      /// @inheritdoc IPluginSetup
  function implementation() external view returns (address) {
    return nftGovernanceImplementation;
  }
}