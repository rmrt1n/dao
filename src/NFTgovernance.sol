pragma solidity ^0.8.17;


import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


contract nftGovernance is Initializable, ERC721Upgradeable, AccessControlEnumerableUpgradeable{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    //using Address for address;
    address public governance;
    uint256 public _tokenID;
    uint256 public _minApprovals;
    uint256 private _proposalCount;
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(address=>bool) public WhiteList;
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
    mapping(address =>bool) voters;
    }




    event ProposalApproval(uint256 indexed proposalId, address indexed approver);
    event ProposalExecutionFailure(uint256 indexed proposalId, address target, bytes data, bytes result);
    event ProposalExecution(uint256 indexed proposalId, address target, bytes data, bytes result);
    event ProposalSubmission(uint256 indexed proposalId, address indexed proposer, address indexed target, bytes data, string description);
    event ProposalVote(uint256 indexed proposalId,uint256 indexed tokenId, address indexed target);
    event ProposalCancled(uint256 indexed proposalId);


    // function initialize(IDAO _dao, address _governance) external initializer{
    //     __PluginCloneable_init(_dao);
    //     //TODO: change the governance address to admin address
    //     governance = _governance;
    // }
    function initialize() public initializer {
        __ERC721_init("NFT Governance Token", "NFTGT");
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }
    //constructor(string memory name, string memory symbol) ERC721(name,symbol){}

     
    // Set the NFT that is going to be used as governance for the DAO
    //TODO Might add an only owner modifier later
    //2 ways pre deploy the memberhip NFT then add the contract address
    function setGovernance(address nftcontract, uint256 tokenID) external{
        require(nftcontract !=address(0),"NFT contract cannot be zero");
        //remove this 2 require statements if u want to test this function. ONLY REMOVE FOR TESTING IT Works once its implemented
        //require(isContract(nftcontract),"Not a contract");
        //require(ERC721(nftcontract).ownerOf(tokenID) == address(this), "NFT is not owned by the contract");
        governance = nftcontract;
        _tokenID = tokenID;
    }

    //set Access Controll List and set the WhiteList mapping to true for each address
    //TODO add onlyOwner modifier later
   function setGovernanceACL(
        address _governanceContract, 
        address[] calldata _proposers, 
        address[] calldata _voters, 
        address[] calldata _executors
    ) external {
        //require(_governanceContract != address(0), "NFT contract cannot be zero");
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

    //function to create new proposals in the governance contract.
    function propose(
        address target,
        bytes memory data,
        string memory proposalHash,
        string memory description
    ) external returns (uint256) {
        require(WhiteList[msg.sender], "Sender not in whitelist");
        require(hasRole(PROPOSER_ROLE, governance), "Does not have proposer role");

        bytes32 hash = keccak256(abi.encode(target, data, proposalHash, block.number));
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

        emit ProposalSubmission(proposalId, msg.sender, target, data, description);

        return proposalId;
    }



    //used to approved proposals by their ID
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

    //usrs with executer role can execute a proposal if threshold has been meet or if it gets enough approvals
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
    
    //Function to cancle the proposal by the proposer
    function cancleProposal(uint256 proposalId) public{
        require(_proposals[proposalId].exists,"Invalid proposal ID");
        require(_proposals[proposalId].proposer == msg.sender,"Only the proposer can cancle");

        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.executed && !proposal.canceled, "Proposal has been cancled or executed");

        proposal.canceled = true;

        emit ProposalCancled(proposalId);
    }

    function vote(uint256 proposalId, uint256 tokenId) external{
        require(_proposals[proposalId].exists,"Invalid proposal ID");
        require(!_proposals[proposalId].executed,"Proposal already executed");
        require(!_proposals[proposalId].canceled,"Proposal already cancled");
        require(ownerOf(tokenId) == msg.sender,"Only NFT owner can vote");

        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.voters[msg.sender], "Already voted");

        proposal.voters[msg.sender] = true;
        proposal.approvalCount++;

        emit ProposalVote(proposalId, tokenId, msg.sender);


    }

    //returns an array of proposal IDS that is used to retrive the poposals from strogae
    //Did this way coz didnt want to change the voters mapping to an array
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

    //TODO add an onlyOwner or onlyAdmin modifier
    // //There is some errors here that got me scratching my head
    // function setQuorum(uint256 _proposalId, uint256 _percentage) external {
    //     Proposal storage proposal = _proposals[_proposalId];
    //     require(proposal.exists, "Proposal does not exist");

    //     uint256 totalVoters = 0;
    //     uint256 numApprovals = proposal.approvalCount;
    //     for (uint256 i = 0; i < numApprovals; i++) {
    //         address voter = proposal.approvals[i];
    //         if (proposal.voters[voter]) {
    //             totalVoters++;
    //         }
    //     }

    //     uint256 totalSupply = 20;//IERC721(nftGovernance).totalSupply();
    //     uint256 requiredVoters = (totalSupply * _percentage) / 100;
    //     require(totalVoters >= requiredVoters, "Quorum not reached");

    //     //proposal.quorum = _percentage;
    // }








    
    //assembly to check if the given address is a contract. Used assembly coz it saves some gas
    function isContract(address _addr) internal view returns (bool){
        uint256 size;
        assembly{
            size:=extcodesize(_addr)
        }
        return size>0;
    }

    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, PluginCloneable) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    function _msgSender() internal view override(ContextUpgradeable) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }



}