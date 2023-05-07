// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/// @dev Imports start here
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {ISubDAOMembership} from "@aragon/osx/core/plugin/membership/ISubDAOMembership.sol";
import {ISubDAOProposal} from "@aragon/osx/core/plugin/proposal/ISubDAOProposal.sol";
import {IMajorityVoting} from "@aragon/osx/plugins/governance/majority-voting/IMajorityVoting.sol";
import {SubDAOMajorityVotingBase} from "@aragon/osx/plugins/governance/majority-voting/SubDAOMajorityVotingBase.sol";
import {RATIO_BASE, _applyRatioCeiled} from "@aragon/osx/plugins/utils/Ratio.sol";
import {SubDAOAddresslist} from "@aragon/osx/plugins/utils/SubDAOAddresslist.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/// @title SubDAOProposal
/// @author ClubDAO
/// @notice This plugin is used to manage the process of creating proposals, voting on proposals, and managing proposal status
/// @dev This plugin is paired with a setup contract that will take care of assigning relevant permissions to the special SubDAO parent
contract SubDAOProposal is
    ISubDAOMembership,
    SubDAOAddresslist,
    SubDAOMajorityVotingBase
{
    using SafeCastUpgradeable for uint256;

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    bytes4 internal constant SUB_DAO_PROPOSAL_INTERFACE_ID =
        this.initialize.selector ^
            this.addAddresses.selector ^
            this.removeAddresses.selector;

    /// @notice The ID of the permission required to call the `addAddresses` and `removeAddresses` functions.
    bytes32 public constant UPDATE_ADDRESSES_PERMISSION_ID =
        keccak256("UPDATE_ADDRESSES_PERMISSION");

    //define a struct that can hold a list of parent DAOs and addresslist in each of it
    struct ParentDAO {
        address parentDAO;
        address[] members;
    }

    /// @notice Initializes the component.
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    /// @param _dao The IDAO interface of the associated DAO.
    /// @param _votingSettings The voting settings.
    /// @param _parentDAO The list of parent DAOs and addresslist in each of it.
    function initialize(
        IDAO _dao,
        VotingSettings calldata _votingSettings,
        ParentDAO[] calldata _parentDAO
    ) external initializer {
        __MajorityVotingBase_init(_dao, _votingSettings);

        for (uint256 i = 0; i < _parentDAO.length; i++) {
            _addAddresses(_parentDAO[i].parentDAO, _parentDAO[i].members);
        }

        for (uint256 i = 0; i < _parentDAO.length; i++) {
            emit MembersAdded({
                _parentDAO: _parentDAO[i].parentDAO,
                members: _parentDAO[i].members
            });
        }
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == SUB_DAO_PROPOSAL_INTERFACE_ID ||
            _interfaceId == type(SubDAOAddresslist).interfaceId ||
            _interfaceId == type(ISubDAOMembership).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Adds new members to the address list.
    /// @param _parentDAO The parent DAO struct.
    /// @dev This function is used during the plugin initialization.
    function addAddresses(
        ParentDAO[] calldata _parentDAO
    ) external auth(UPDATE_ADDRESSES_PERMISSION_ID) {
        for (uint256 i = 0; i < _parentDAO.length; i++) {
            _addAddresses(_parentDAO[i].parentDAO, _parentDAO[i].members);
        }

        for (uint256 i = 0; i < _parentDAO.length; i++) {
            emit MembersAdded({
                _parentDAO: _parentDAO[i].parentDAO,
                members: _parentDAO[i].members
            });
        }
    }

    /// @notice Removes existing members from the address list.
    /// @param _parentDAO The parent DAO struct.
    function removeAddresses(
        ParentDAO[] calldata _parentDAO
    ) external auth(UPDATE_ADDRESSES_PERMISSION_ID) {
        for (uint256 i = 0; i < _parentDAO.length; i++) {
            _removeAddresses(_parentDAO[i].parentDAO, _parentDAO[i].members);
        }

        for (uint256 i = 0; i < _parentDAO.length; i++) {
            emit MembersAdded({
                _parentDAO: _parentDAO[i].parentDAO,
                members: _parentDAO[i].members
            });
        }
    }

    /// @notice Returns the total voting power checkpointed for a specific block number.
    /// @param _blockNumber The block number.
    /// @return The total voting power.
    function totalVotingPower(
        address _parentDAO,
        uint256 _blockNumber
    ) public view returns (uint256) {
        return addresslistLengthAtBlock(_parentDAO, _blockNumber);
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
    /// @param _parentDAOs The parent DAOs involved in managing the SubDAO.
    /// @dev The parent DAOs are encoded as follows:
    /// @return proposalId The ID of the proposal.
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap,
        uint64 _startDate,
        uint64 _endDate,
        VoteOption _voteOption,
        bool _tryEarlyExecution,
        address[] calldata _parentDAOs
    ) external returns (uint256 proposalId) {
        uint64 snapshotBlock;
        unchecked {
            snapshotBlock = block.number.toUint64() - 1;
        }

        bool isMemberOfParentDAO = false;
        for (uint256 i = 0; i < _parentDAOs.length; i++) {
            if (isListedAtBlock(_parentDAOs[i], _msgSender(), snapshotBlock)) {
                isMemberOfParentDAO = true;
                break;
            }
        }

        if (!isMemberOfParentDAO && minProposerVotingPower() != 0) {
            revert ProposalCreationForbidden(_msgSender());
        }

        {
            proposalId = _createProposal({
                _creator: _msgSender(),
                _parentDAOs: _parentDAOs,
                _metadata: _metadata,
                _startDate: _startDate,
                _endDate: _endDate,
                _actions: _actions,
                _allowFailureMap: _allowFailureMap
            });
        }

        // Store proposal related information
        Proposal storage proposal_ = proposals[proposalId];

        (
            proposal_.parameters.startDate,
            proposal_.parameters.endDate
        ) = _validateProposalDates({_start: _startDate, _end: _endDate});
        proposal_.parameters.snapshotBlock = snapshotBlock;
        proposal_.parameters.votingMode = votingMode();
        proposal_.parameters.supportThreshold = supportThreshold();
        proposal_.parameters.minVotingPower = _applyRatioCeiled(
            totalVotingPower(snapshotBlock),
            minParticipation()
        );
        proposal_.parameters._parentDAOs = _parentDAOs;

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

    /// @notice Checks if the given address is a member of a parent DAO.
    /// @dev Check if the member has the voting token associated with the parent DAO.
    /// @param _account The address of the member.
    /// @param _parentDAO The address of the parent DAO.
    /// @return Returns `true` if the given address is a member of the parent DAO.
    function isMember(
        address _parentDAO,
        address _account
    ) external view returns (bool) {
        return isListed(_parentDAO, _account);
    }

    /// @inheritdoc SubDAOMajorityVotingBase
    function _vote(
        uint256 _proposalId,
        VoteOption _voteOption,
        address _voter,
        bool _tryEarlyExecution
    ) internal override {
        Proposal storage proposal_ = proposals[_proposalId];

        VoteOption state = proposal_.voters[_voter];

        // Remove the previous vote.
        if (state == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes - 1;
        } else if (state == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no - 1;
        } else if (state == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain - 1;
        }

        // Store the updated/new vote for the voter.
        if (_voteOption == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes + 1;
        } else if (_voteOption == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no + 1;
        } else if (_voteOption == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain + 1;
        }

        proposal_.voters[_voter] = _voteOption;

        emit VoteCast({
            proposalId: _proposalId,
            voter: _voter,
            voteOption: _voteOption,
            votingPower: 1
        });

        if (_tryEarlyExecution && _canExecute(_proposalId)) {
            _execute(_proposalId);
        }
    }

    function _canVote(
        uint256 _proposalId,
        address _parentDAO,
        address _account,
        VoteOption _voteOption
    ) internal view returns (bool) {
        Proposal storage proposal_ = proposals[_proposalId];

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
            !isListedAtBlock(
                _parentDAO,
                _account,
                proposal_.parameters.snapshotBlock
            )
        ) {
            return false;
        }

        // The voter has already voted but vote replacement is not allowed.
        if (
            proposal_.voters[_account] != VoteOption.None &&
            proposal_.parameters.votingMode != VotingMode.VoteReplacement
        ) {
            return false;
        }

        return true;
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private __gap;

    function totalVotingPower(
        uint256 _blockNumber
    ) public view virtual override returns (uint256) {}

    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap,
        uint64 _startDate,
        uint64 _endDate,
        VoteOption _voteOption,
        bool _tryEarlyExecution
    ) external virtual override returns (uint256 proposalId) {}

    function _canVote(
        uint256 _proposalId,
        address _voter,
        VoteOption _voteOption
    ) internal view virtual override returns (bool) {}
}
