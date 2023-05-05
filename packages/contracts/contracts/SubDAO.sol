// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {IMembership} from "@aragon/osx/core/plugin/membership/IMembership.sol";
import {IProposal} from "@aragon/osx/core/plugin/proposal/IProposal.sol";
import {IMajorityVoting} from "@aragon/osx/plugins/governance/majority-voting/IMajorityVoting.sol";
import {MajorityVotingBase} from "@aragon/osx/plugins/governance/majority-voting/MajorityVotingBase.sol";
import {RATIO_BASE, _applyRatioCeiled} from "@aragon/osx/plugins/utils/Ratio.sol";

import {IVotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/// @title SubDAO
/// @author ClubDAO
/// @notice This plugin is used to create a subDAO from 1 or more parent DAOs
/// @dev This plugin is paired with a setup contract that will take care of assigning relevant permissions to the special SubDAO parent
/// @dev Ideal flow:-
/* 
1. This plugin will check that the proposal to create a SubDAO has passed 
2. Gets the necessary params to create this new DAO (subdomain, metadata, URI) 
3. The daoFactory in the plugin will create the new DAO 
4. Agreed budget will be transferred to the treasury of this new DAO
5. Hats protocol will be used to assign special roles to specific members of the new DAO using proposal details
6. There should be a self-destruct function used to destroy the DAO once the time period has passed (TBC)
*/
contract SubDAO is IMembership, IProposal, MajorityVotingBase {
    using SafeCastUpgradeable for uint256;

    /// @notice The ID of the permission required to call the `execute` function.
    bytes32 public constant SUBDAO_EXECUTE_PERMISSION_ID =
        keccak256("SUBDAO_EXECUTE_PERMISSION");

    /// @notice A mapping of ParentDAOs to their voting tokens
    mapping(address => IVotesUpgradeable) public parentDAOsAndTokens;

    /// @notice An array of Parent DAOs only.
    address[] public parentDAOs;

    /// @notice A mapping of SubDAOs to their parent DAOs
    /// @dev One-to-many relationship between SubDAOs to ParentDAOs. One SubDAO can have many ParentDAOs.
    mapping(address => address[]) public subDAOsToParentDAOs;

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    bytes4 private constant TOKEN_VOTING_INTERFACE_ID =
        this.initialize.selector ^ this.getVotingToken.selector;

    /// @notice Thrown if the voting power is zero
    error NoVotingPower();

    /// @notice Initializes the contract.
    /// @param _dao The associated DAO.
    /// @param _votingSettings The voting settings.
    /// @param _parentDAOsAndTokens A mapping of Parent DAOs to their voting tokens
    function initialize(
        IDAO _dao,
        VotingSettings memory _votingSettings,
        mapping(address => IVotesUpgradeable) memory _parentDAOsAndTokens
    ) external initializer {
        __MajorityVotingBase_init(_dao, _votingSettings);

        // Set the Parent DAOs and their voting tokens
        parentDAOsAndTokens = _parentDAOsAndTokens;

        // Set the Parent DAOs
        parentDAOs = _parentDAOsAndTokens.keys();

        //Emit an event to state the Parent DAOs that have been added
        emit MembersAdded(parentDAOs);
    }

    /// @notice Update the parent DAOs and their voting tokens
    /// @param _parentDAOsAndTokens A mapping of Parent DAOs to their voting tokens
    /// @dev This function can only be called by the DAO
    function updateParentDAOsAndTokens(
        mapping(address => IVotesUpgradeable) memory _parentDAOsAndTokens
    ) external {
        require(
            msg.sender == address(dao()),
            "SubDAO: only the DAO can update the parent DAOs and their voting tokens"
        );

        for (uint i = 0; i < parentDAOs.length; i++) {
            address parentDAO = parentDAOs[i];
            parentDAOsAndTokens[parentDAO].push(
                _parentDAOsAndTokens[parentDAO]
            );
        }

        // Add any new parent DAOs not already in the mapping
        for (uint i = 0; i < _parentDAOsAndTokens.length; i++) {
            address parentDAO = _parentDAOsAndTokens[i];
            if (parentDAOsAndTokens[parentDAO] == address(0)) {
                parentDAOs.push(parentDAO);
                parentDAOsAndTokens[parentDAO] = _parentDAOsAndTokens[
                    parentDAO
                ];
            }
        }

        // Emit an event to state the Parent DAOs that have been added
        emit MembersAdded(parentDAOs);
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == TOKEN_VOTING_INTERFACE_ID ||
            _interfaceId == type(IMembership).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice getter function for the voting token.
    /// @dev public function also useful for registering interfaceId and for distinguishing from majority voting interface.
    /// @return The token used for voting.
    function getVotingToken(
        address _parentDAO
    ) public view returns (IVotesUpgradeable) {
        return parentDAOsAndTokens[_parentDAO];
    }

    /// @notice Returns the total voting power checkpointed for a specific block number.
    /// @param _blockNumber The block number.
    /// @return The total voting power.
    function totalVotingPower(
        uint256 _blockNumber,
        address _parentDAO
    ) public view virtual returns (uint256) {
        return parentDAOsAndTokens[_parentDAO].getPastTotalSupply(_blockNumber);
    }

    /// @notice Checks if the given address is a member of a parent DAO.
    /// @dev Check if the member has the voting token associated with the parent DAO.
    /// @param _member The address of the member.
    /// @param _parentDAO The address of the parent DAO.
    /// @return Returns `true` if the given address is a member of the parent DAO.
    function isMember(
        address _member,
        address _parentDAO
    ) public view returns (bool) {
        return parentDAOsAndTokens[_parentDAO].balanceOf(_member) > 0;
    }

    /// @notice Creates a new majority voting proposal.
    /// @param _metadata The metadata of the proposal.
    /// @dev The metadata is an IPFS url containing the following information in JSON format:
    /// - `string proposalName`: The name of the proposal.
    /// - `string proposalDescription`: The description of the proposal.
    /// - `string subDAOName`: The subdomain of the SubDAO.
    /// - `string subDAODescription`: The description of the SubDAO.
    /// - `address[] parentDAOs`: The addresses of the parent DAOs involved in managing the SubDAO.
    /// - `uint256 budget`: The budget requested for the SubDAO in USDC.
    /// - `uint256 timePeriod`: The time period in epoch at which the SubDAO should be destroyed.
    /// - `mapping(address => uint256) roles`: A mapping of members to their roles in the SubDAO (Mint hats according to roles). The roles are encoded as follows:
    ///     - `0`: No role.
    ///     - `1`: SubDAO Manager.
    ///     - `2`: SubDAO Co-Manager.
    ///     - `3`: SubDAO Member.
    /// @param _actions The actions that will be executed after the proposal passes.
    /// @dev The actions are encoded as follows:
    /// - `address to`: The address to call.
    /// - `uint256 value`: The native token value to be sent with the call.
    /// - `bytes calldata data`: The bytes-encoded function selector and calldata for the call.
    /// @dev Actions that can be done by the SubDAO:
    /// - `createSubDAO`: Creates a new SubDAO.
    /// - `fillTreasury`: Fills the treasury of the SubDAO with the agreed budget.
    /// - `setTimePeriod`: Sets the time period of the SubDAO.
    /// - `setRoles`: Sets the roles of the members of the SubDAO.
    /// - `setParentDAOs`: Update the subDAOsToParentDAOs mapping.
    /// @param _allowFailureMap Allows proposal to succeed even if an action reverts. Uses bitmap representation. If the bit at index `x` is 1, the tx succeeds even if the action at `x` failed. Passing 0 will be treated as atomic execution.
    /// @dev Set to 0 to revert the whole proposal if any action fails.
    /// @param _startDate The start date of the proposal vote. If 0, the current timestamp is used and the vote starts immediately.
    /// @param _endDate The end date of the proposal vote. If 0, `_startDate + minDuration` is used.
    /// @param _voteOption The chosen vote option to be casted on proposal creation.
    /// @dev The vote option is in an enum encoded as follows:
    /// - None
    /// - Abstain
    /// - Yes
    /// - No
    /// @param _tryEarlyExecution If `true`,  early execution is tried after the vote cast. The call does not revert if early execution is not possible.
    /// @dev Set to 'true' to try early execution after the vote cast.
    /// @return proposalId The ID of the proposal.
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap,
        uint64 _startDate,
        uint64 _endDate,
        VoteOption _voteOption,
        bool _tryEarlyExecution
    ) external override returns (uint256 proposalId) {
        uint256 snapshotBlock;
        unchecked {
            snapshotBlock = block.number - 1;
        }

        uint256 totalVotingPower_ = totalVotingPower(snapshotBlock);

        /// @dev msg.sender has to be from a parent DAO not an EOA.
        if (totalVotingPower_ == 0) {
            revert NoVotingPower();
        }

        //TODO: check if msg.sender is a DAO or an EOA.
        IVotesUpgradeable votingToken = getVotingToken();

        if (
            votingToken.getPastVotes(_msgSender(), snapshotBlock) <
            minProposerVotingPower()
        ) {
            revert ProposalCreationForbidden(_msgSender());
        }

        proposalId = _createProposal({
            _creator: _msgSender(),
            _metadata: _metadata,
            _startDate: _startDate,
            _endDate: _endDate,
            _actions: _actions,
            _allowFailureMap: _allowFailureMap
        });

        // Store proposal related information
        Proposal storage proposal_ = proposals[proposalId];

        (
            proposal_.parameters.startDate,
            proposal_.parameters.endDate
        ) = _validateProposalDates(_startDate, _endDate);
        proposal_.parameters.snapshotBlock = snapshotBlock.toUint64();
        proposal_.parameters.votingMode = votingMode();
        proposal_.parameters.supportThreshold = supportThreshold();
        proposal_.parameters.minVotingPower = _applyRatioCeiled(
            totalVotingPower_,
            minParticipation()
        );

        // Reduce costs
        if (_allowFailureMap != 0) {
            proposal_.allowFailureMap = _allowFailureMap;
        }

        for (uint256 i; i < _actions.length; ) {
            proposal_.actions.push(_actions[i]);
            unchecked {
                ++i;
            }
        }

        if (_voteOption != VoteOption.None) {
            vote(proposalId, _voteOption, _tryEarlyExecution);
        }
    }

    function _vote(
        uint256 _proposalId,
        VoteOption _voteOption,
        address _voter,
        bool _tryEarlyExecution
    ) internal override {
        Proposal storage proposal_ = proposals[_proposalId];

        IVotesUpgradeable votingToken = getVotingToken();

        // This could re-enter, though we can assume the governance token is not malicious
        uint256 votingPower = votingToken.getPastVotes(
            _voter,
            proposal_.parameters.snapshotBlock
        );
        VoteOption state = proposal_.voters[_voter];

        // If voter had previously voted, decrease count
        if (state == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes - votingPower;
        } else if (state == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no - votingPower;
        } else if (state == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain - votingPower;
        }

        // write the updated/new vote for the voter.
        if (_voteOption == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes + votingPower;
        } else if (_voteOption == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no + votingPower;
        } else if (_voteOption == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain + votingPower;
        }

        proposal_.voters[_voter] = _voteOption;

        emit VoteCast({
            proposalId: _proposalId,
            voter: _voter,
            voteOption: _voteOption,
            votingPower: votingPower
        });

        if (_tryEarlyExecution && _canExecute(_proposalId)) {
            _execute(_proposalId);
        }
    }

    function _canVote(
        uint256 _proposalId,
        address _voter,
        VoteOption _voteOption
    ) internal view override returns (bool) {
        Proposal storage proposal_ = proposals[_proposalId];

        IVotesUpgradeable votingToken = getVotingToken();

        // The proposal vote hasn't started or has already ended.
        if (!_isProposalOpen(proposal_)) {
            return false;
        }

        // The voter votes `None` which is not allowed.
        if (_voteOption == VoteOption.None) {
            return false;
        }

        // The voter has no voting power.
        if (
            votingToken.getPastVotes(
                _voter,
                proposal_.parameters.snapshotBlock
            ) == 0
        ) {
            return false;
        }

        // The voter has already voted but vote replacement is not allowed.
        if (
            proposal_.voters[_voter] != VoteOption.None &&
            proposal_.parameters.votingMode != VotingMode.VoteReplacement
        ) {
            return false;
        }

        return true;
    }

    function isMember(address _account) external view override returns (bool) {}

    function totalVotingPower(
        uint256 _blockNumber
    ) public view virtual override returns (uint256) {}
}
