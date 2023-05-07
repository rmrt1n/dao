pragma solidity 0.8.17;

import {PluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {nftGovernance} from "./NFTGovernance.sol";
import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IDAO, DAO} from "@aragon/osx/core/dao/DAO.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract nftGovernanceSetup is PluginSetup {
    address private immutable nftGovernanceImplementation;

    constructor(address _dao, address admin, IERC721 _nft) {
        //change address _dao back to IDAO _dao later
        nftGovernanceImplementation = address(
            new nftGovernance(IDAO(_dao), admin, _nft)
        ); //remove this constructor later and add in in prepareInstallation
    }

    function prepareInstallation(
        address _dao,
        bytes calldata _data
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        (address admin, address nft) = abi.decode(_data, (address, address));

        plugin = Clones.clone(nftGovernanceImplementation);

        nftGovernance(plugin);

        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](2);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("PROPOSER_ROLE")
        });

        permissions[1] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("ADMIN_EXECUTE_PERMISSION")
        });
        preparedSetupData.permissions = permissions;
    }

    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        pure
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("ADMIN_EXECUTE_PERMISSION")
        });
    }

    function implementation() external view returns (address) {
        return nftGovernanceImplementation;
    }
}
