// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/// @dev Imports start here
import {PluginCloneable, IDAO} from "@aragon/osx/core/plugin/PluginCloneable.sol";
import {IRoleMembership} from "@aragon/osx/core/plugin/membership/IRoleMembership.sol";
import "hats-protocol/src/Interfaces/IHats.sol";

/// @title SubDAO Roles
/// @author ClubDAO
/// @notice This plugin is used to assign special roles to specific members of the new DAO using proposal details and the hats protocol
/// @dev This plugin is paired with a setup contract that will take care of assigning relevant permissions to the special SubDAO parent
contract SubDAORoles is PluginCloneable, IRoleMembership {
    /// @notice The ID of the permission required to call the `execute` function.
    bytes32 public constant ROLE_ASSIGN_PERMISSION_ID =
        keccak256("SUB_DAO_ROLES_ASSIGN_PERMISSION");

    /// @dev The interface for Hats Protocol
    IHats public hatsProtocol;

    /// @dev the variable that stores the token ID of the topHat
    uint256 public topHatId;

    /// @dev The ID of the newly created hat. not to be confused with the topHat
    uint256 public newHatId;

    /// @notice Initializes the contract.
    /// @param _dao The associated DAO.
    // @param _hatsProtocol The address of the deployed hats protocol on chain
    function initialize(
        IDAO _dao,
        address _hatsProtocol,
        address _targetDAO,
        string memory _details,
        string memory _imageURI
    ) external initializer {
        __PluginCloneable_init(_dao);
        hatsProtocol = IHats(_hatsProtocol);
        topHatId = hatsProtocol.mintTopHat(_targetDAO, _details, _imageURI);
    }

    /// @notice Function to create a hat for a target DAO
    function createHat(
        string calldata _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string calldata _imageURI
    ) external returns (uint256 newHatId) {
        return
            newHatId = hatsProtocol.createHat(
                topHatId,
                _details,
                _maxSupply,
                _eligibility,
                _toggle,
                _mutable,
                _imageURI
            );
    }

    /// @notice Function to mint hat to a target member in a DAO\
    /// @param _hatId The ID of the hat to be minted
    /// @param _wearer The address of the member to whom the hat is to be minted
    function mintHat(
        uint256 _hatId,
        address _wearer
    ) public returns (bool success) {
        return hatsProtocol.mintHat(_hatId, _wearer);
    }

    /// @dev Function to renounce the hat
    function renounceHat(uint256 _hatId) external {
        hatsProtocol.renounceHat(_hatId);
    }

    function isMember(address _account) external view override returns (bool) {}
}
