pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
//import {PluginCloneable, IDAO} from '@aragon/osx/core/plugin/PluginCloneable.sol';
import {Plugin, IDAO} from "@aragon/osx/core/plugin/Plugin.sol";

//mport {IDAO, DAO} from '@aragon/osx/core/dao/DAO.sol';
//import {PluginCloneable, IDAO} from '@aragon/osx/core/plugin/PluginCloneable.sol';

contract nftGovernance is Plugin {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    //using Address for addres
    address public governance;
    //address public admin;
    uint256 public _tokenID;
    uint256 public _minApprovals;
    uint256 private _proposalCount;
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE"); //keep
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_EXECUTE_PERMISSION_ID =
        keccak256("ADMIN_EXECUTE_PERMISSION"); //keep

    mapping(address => bool) public WhiteList;
    mapping(uint256 => Proposal) private _proposals;
    mapping(bytes32 => bool) private _proposalExists;

    struct Proposal {
        bool exists;
        bool executed;
        bool canceled;
        uint256 id;
        uint256 proposalTime;
        uint256 approvalCount;
        address proposer;
        address target;
        string proposalHash;
        string description;
        bytes data;
        mapping(address => bool) approvals;
        mapping(address => bool) voters;
    }

    event ProposalApproval(
        uint256 indexed proposalId,
        address indexed approver
    );
    event ProposalExecutionFailure(
        uint256 indexed proposalId,
        address target,
        bytes data,
        bytes result
    );
    event ProposalExecution(
        uint256 indexed proposalId,
        address target,
        bytes data,
        bytes result
    );
    event ProposalSubmission(
        uint256 indexed proposalId,
        address indexed proposer,
        address indexed target,
        bytes data,
        string description
    );
    event ProposalVote(
        uint256 indexed proposalId,
        uint256 indexed tokenId,
        address indexed target
    );
    event ProposalCancled(uint256 indexed proposalId);

    // function initialize(IDAO _dao, address _admin) external initializer{
    //     __PluginCloneable_init(_dao);
    //     //TODO: change the governance address to admin address
    //     admin = _admin;
    // }
    //function initialize(IDAO _dao, address _admin) public initializer {
    // __ERC721_init("NFT Governance Token", "NFTGT");
    // __AccessControlEnumerable_init();
    //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    //_setupRole(OPERATOR_ROLE, msg.sender);
    //}
    // constructor(string memory name, string memory symbol) ERC721(name,symbol){}
    address public immutable admin;
    IERC721 public immutable nft;

    constructor(IDAO _dao, address _admin, IERC721 _nft) Plugin(_dao) {
        admin = _admin;
        nft = _nft;
    }

    // function initialize(IDAO _dao, address _admin, IERC721 _nft) public{
    //     __PluginCloneable_init(_dao);
    // }

    // Set the NFT that is going to be used as governance for the DAO
    //TODO Might add an only owner modifier later
    //2 ways pre deploy the memberhip NFT then add the contract address
    function setGovernance(
        address nftcontract,
        uint256 tokenID
    ) external auth(ADMIN_EXECUTE_PERMISSION_ID) {
        require(nftcontract != address(0), "NFT contract cannot be zero");
        //remove this 2 require statements if u want to test this function. ONLY REMOVE FOR TESTING IT Works once its implemented
        require(isContract(nftcontract), "Not a contract");
        require(
            IERC721(nftcontract).ownerOf(tokenID) == address(this),
            "NFT is not owned by the contract"
        );
        governance = nftcontract;
        _tokenID = tokenID;
    }

    //function to create new proposals in the governance contract.
    function propose(
        address target,
        bytes memory data,
        string memory proposalHash,
        string memory description
    ) external auth(PROPOSER_ROLE) returns (uint256) {
        bytes32 hash = keccak256(
            abi.encode(target, data, proposalHash, block.number)
        );
        require(!_proposalExists[hash], "Identical proposal already exists");

        uint256 proposalId = ++_proposalCount;
        Proposal storage proposal = _proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.target = target;
        proposal.data = data;
        proposal.proposalHash = proposalHash;
        proposal.description = description;
        proposal.exists = true;
        proposal.executed = false;
        proposal.canceled = false;
        proposal.approvalCount = 0;

        _proposalExists[hash] = true;

        emit ProposalSubmission(
            proposalId,
            msg.sender,
            target,
            data,
            description
        );

        return proposalId;
    }

    //used to approved proposals by their ID
    function approve(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.canceled, "Proposal has been canceled");

        proposal.approvals[msg.sender] = true;
        proposal.approvalCount++;

        emit ProposalApproval(proposalId, msg.sender);
    }

    //usrs with executer role can execute a proposal if threshold has been meet or if it gets enough approvals

    function execute(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(
            proposal.approvalCount >= _minApprovals,
            "Proposal has not met minimum approvals"
        );
        require(!proposal.executed, "Proposal has already been executed");

        proposal.executed = true;

        (bool success, bytes memory result) = proposal.target.call(
            proposal.data
        );

        if (success) {
            emit ProposalExecution(
                proposalId,
                proposal.target,
                proposal.data,
                result
            );
        } else {
            emit ProposalExecutionFailure(
                proposalId,
                proposal.target,
                proposal.data,
                result
            );
            proposal.executed = false;
        }
    }

    //Function to cancle the proposal by the proposer
    function cancleProposal(uint256 proposalId) public {
        require(_proposals[proposalId].exists, "Invalid proposal ID");
        require(
            _proposals[proposalId].proposer == msg.sender,
            "Only the proposer can cancle"
        );

        Proposal storage proposal = _proposals[proposalId];
        require(
            !proposal.executed && !proposal.canceled,
            "Proposal has been cancled or executed"
        );

        proposal.canceled = true;

        emit ProposalCancled(proposalId);
    }

    function vote(uint256 proposalId, uint256 tokenId) external {
        require(_proposals[proposalId].exists, "Invalid proposal ID");
        require(!_proposals[proposalId].executed, "Proposal already executed");
        require(!_proposals[proposalId].canceled, "Proposal already cancled");
        //require(ownerOf(tokenId) == msg.sender,"Only NFT owner can vote");

        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.voters[msg.sender], "Already voted");

        proposal.voters[msg.sender] = true;
        proposal.approvalCount++;

        emit ProposalVote(proposalId, tokenId, msg.sender);
    }

    //returns an array of proposal IDS that is used to retrive the poposals from strogae

    function getProposals() public view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](_proposalCount);
        uint256 count = 0;

        for (uint256 i = 1; i <= _proposalCount; i++) {
            if (_proposals[i].exists) {
                proposalIds[count] = i;
                count++;
            }
        }

        // Resize the array to remove unused elements
        assembly {
            mstore(proposalIds, count)
        }

        return proposalIds;
    }

    //assembly to check if the given address is a contract. Used assembly coz it saves some gas
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
