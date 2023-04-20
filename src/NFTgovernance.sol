pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract nftGovernance is ERC721,AccessControl{
    address public governance;
    uint256 public _tokenID;
    uint256 public _minApprovals;
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(address=>bool) public WhiteList;
    mapping(uint256 => Proposal) private _proposals;

    struct Proposal {
    bool exists;
    bool executed;
    bool canceled;
    uint256 id;
    address proposer;
    address target;
    bytes data;
    uint256 proposalTime;
    mapping(address => bool) approvals;
    uint256 approvalCount;
    }


    event ProposalApproval(uint256 indexed proposalId, address indexed approver);
    event ProposalExecutionFailure(uint256 indexed proposalId, address target, bytes data, bytes result);
    event ProposalExecution(uint256 indexed proposalId, address target, bytes data, bytes result);









    constructor(string memory name, string memory symbol) ERC721(name,symbol){}
     
    // Set the NFT that is going to be used as governance for the DAO
    //TODO Might add an only owner modifier later
    function setGovernance(address nftcontract, uint256 tokenID) external{
        require(nftcontract !=address(0),"NFT contract cannot be zero");
        require(isContract(nftcontract),"Not a contract");
        require(ERC721(nftcontract).ownerOf(tokenID) == address(this), "NFT is not owned by the contract");
        governance = nftcontract;
        _tokenID = tokenID;
    }

    //set Access Controll List and set the WhiteList mapping to true for each address
    //TODO add onlyOwner modifier later
   function setGovernanceACL(address _governanceContract, address[] calldata _proposers, address[] calldata _voters, address[] calldata _executors) external {
        require(_governanceContract != address(0), "NFT contract cannot be zero");
        require(_proposers.length > 0, "At least one proposer is required");
        require(_voters.length > 0, "At least one voter is required");
        require(_executors.length > 0, "At least one executor is required");
        
        //set governance contract 
        governance = _governanceContract;

        //assign roles to proposers,voters,executers

        for(uint256 i;i<_proposers.length;++i){
            _setupRole(PROPOSER_ROLE, _proposers[i]);
            WhiteList[_proposers[i]] = true;
        }

        for(uint256 i; i<_voters.length;++i){
            _setupRole(VOTER_ROLE, _voters[i]);
            WhiteList[_voters[i]] = true;

        }

        for (uint256 i; i < _executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, _executors[i]);
            WhiteList[_executors[i]] = true;
        }


    }

    function approve(uint256 proposalId) external {
        require(WhiteList[msg.sender], "Sender not in whitelist");
        require(hasRole(PROPOSER_ROLE, governance), "Does not have proposer role");

        Proposal storage proposal = _proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.canceled, "Proposal has been canceled");

        proposal.approvals[msg.sender] = true;
        proposal.approvalCount++;

        emit ProposalApproval(proposalId, msg.sender);
    }

    function execute(uint256 proposalId) external {
        require(hasRole(EXECUTOR_ROLE, msg.sender), "Caller is not an executor");

        Proposal storage proposal = _proposals[proposalId];
        require(proposal.exists, "Proposal does not exist");
        require(proposal.approvalCount >= _minApprovals, "Proposal has not met minimum approvals");
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.canceled, "Proposal has been canceled");

        proposal.executed = true;

        bool success;
        bytes memory result;
        (success, result) = proposal.target.call(proposal.data);

        if (success) {
            emit ProposalExecution(proposalId, proposal.target, proposal.data, result);
        } else {
            emit ProposalExecutionFailure(proposalId, proposal.target, proposal.data, result);
            proposal.executed = false;
        }
    }
    

    function isContract(address _addr) internal view returns (bool){
        uint256 size;
        assembly{
            size:=extcodesize(_addr)
        }
        return size>0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}