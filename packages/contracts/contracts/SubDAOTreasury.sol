// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {IMembership} from "@aragon/osx/core/plugin/membership/IMembership.sol";
import {IProposal} from "@aragon/osx/core/plugin/proposal/IProposal.sol";
import {IMajorityVoting} from "@aragon/osx/plugins/governance/majority-voting/IMajorityVoting.sol";
import {MajorityVotingBase} from "@aragon/osx/plugins/governance/majority-voting/MajorityVotingBase.sol";
import {RATIO_BASE, _applyRatioCeiled} from "@aragon/osx/plugins/utils/Ratio.sol";

import {IVotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SubDAO
/// @author ClubDAO
/// @notice This plugin is used to create a subDAO from 1 or more parent DAOs
/// @dev This plugin is paired with a setup contract that will take care of assigning relevant permissions to the special SubDAO parent
/// @dev Ideal flow:-
/* 
1. This plugin will check that the proposal to create a SubDAO has passed (SubDAO Proposal)
2. Gets the necessary params to create this new DAO (subdomain, metadata, URI) (the call happens here)
3. The daoFactory in the plugin will create the new DAO (the call happens here)
4. Agreed budget will be transferred to the treasury of this new DAO
5. Hats protocol will be used to assign special roles to specific members of the new DAO using proposal details (SubDAO Roles)
6. There should be a function that checks if the SubDAO active period has ended and if so, any actions will be reverted.
*/
contract SubDAOTreasury is IMembership, MajorityVotingBase {
    using SafeCastUpgradeable for uint256;

    /// @notice The ID of the permission required to call the `execute` function.
    bytes32 public constant SUBDAO_EXECUTE_PERMISSION_ID =
        keccak256("SUBDAO_EXECUTE_PERMISSION");

    /// @notice A mapping of ParentDAOs to their voting tokens
    mapping(address => IVotesUpgradeable) public parentDAOsAndTokens;

    /// @notice An array of Parent DAOs only.
    address[] public parentDAOs;

    /// @notice A mapping of SubDAOs to their parent DAOs
    /// @dev One-to-many relationship between SubDAOs to ParentDAOs.
    ///      One SubDAO can have many ParentDAOs.
    mapping(address => address[]) public subDAOsToParentDAOs;

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    // bytes4 private constant TOKEN_VOTING_INTERFACE_ID =
    //     this.initialize.selector ^ this.getVotingToken.selector;

    /// @notice Thrown if the voting power is zero
    error NoVotingPower();

    // Define an event to emit when a subDAO is created
    event SubDAOCreated(
        address indexed subDAO,
        address[] parentDAOs,
        string subdomain,
        string metadata,
        string uri,
        uint256 budget
    );

    /// @notice Initializes the contract.

    function subDAOProposalPassed(
        uint256 proposalId
    ) public view returns (bool) {
        // Retrieve the proposal from the storage
        Proposal storage proposal_ = proposals[proposalId];

        // Check if the proposal has already ended
        if (block.timestamp < proposal_.parameters.endDate) {
            return false;
        }

        // Check if the proposal has enough support from the voters
        uint256 totalVotingPower_ = totalVotingPower(
            proposal_.parameters.snapshotBlock
        );
        uint256 totalVotes_ = proposal_.votes[uint256(VoteOption.Yes)];
        uint256 totalAbstentions_ = proposal_.votes[
            uint256(VoteOption.Abstain)
        ];
        uint256 totalNoVotes_ = proposal_.votes[uint256(VoteOption.No)];
        uint256 supportThreshold_ = _applyRatioCeiled(
            totalVotingPower_,
            proposal_.parameters.supportThreshold
        );
        if (
            totalVotes_ < supportThreshold_ ||
            totalNoVotes_ >= supportThreshold_
        ) {
            return false;
        }

        // Check if the proposal was executed
        if (proposal_.isExecuted) {
            return false;
        }

        // Check if the proposal was successful
        if (
            proposal_.votes[uint256(proposal_.parameters.votingMode)] <
            supportThreshold_
        ) {
            return false;
        }

        return true;
    }

    //Gets the necessary params to create this new DAO (subdomain, metadata, URI) (the call happens in the front end)
    function getParams(
        string calldata _metadata,
        string calldata _uri,
        string calldata _subdomain
    )
        external
        pure
        returns (
            string memory metadata,
            string memory uri,
            string memory subdomain
        )
    {
        metadata = _metadata;
        uri = _uri;
        subdomain = _subdomain;
        return (metadata, uri, subdomain);
    }

    function transferAgreedBudget(address daoAddress) external {
        uint256 agreedBudget = 0.1 ether; // hardcoded agreed budget of 0.1 ether
        // transfer agreed budget to the DAO treasury
        // (assuming the DAO has a "treasury" variable of type address that represents the treasury address)
        IERC20(daoAddress).transferFrom(msg.sender, daoAddress, agreedBudget);
    }
}
