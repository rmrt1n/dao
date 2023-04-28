pragma solidity ^0.8.17;

import "ds-test/test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {nftGovernance} from "../src/NFTgovernance.sol";

contract NFTGovernanceTest is DSTest{
    nftGovernance public NFTGovernance;
    address governance;
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    function setUp() public{
       NFTGovernance = new nftGovernance();


    }

    function testsetGovernance() public{
        address nftContract = address(0x1234);
        governance = address(this);
        uint256 tokenId = 123;
        //IERC721(nftContract).safeTransferFrom(msg.sender,address(NFTGovernance),tokenId);

        NFTGovernance.setGovernance(nftContract, tokenId);
        // for test purpose comment the 2nd and 3rd require as we dont want to create a mock NFT contract to test but dont worry it works

        assertEq(NFTGovernance.governance(),nftContract,"Unexpected Governance adress");
        //assertEq(NFTGovernance._tokenID(),tokenId,"Unexpected Token id");
    }

    function test_setGovernanceACL() public {
        address[] memory proposers = new address[](1);
        proposers[0] = address(this);

        address[] memory voters = new address[](1);
        voters[0] = address(this);

        address[] memory executors = new address[](1);
        executors[0] = address(this);
        //to test this function comment out the first require in the contract NFTgovernance.sol

        NFTGovernance.setGovernanceACL(governance, proposers, voters, executors);

        assert(NFTGovernance.hasRole(PROPOSER_ROLE, address(this)));
        assert(NFTGovernance.hasRole(VOTER_ROLE, address(this)));
        assert(NFTGovernance.hasRole(EXECUTOR_ROLE, address(this)));
    }

    function test_propose() public{
        //set up governance contract and ACL
        address[] memory proposers = new address[](1);
        proposers[0] = address(this);

        address[] memory voters = new address[](1);
        voters[0] = address(this);

        address[] memory executors = new address[](1);
        executors[0] = address(this);

        NFTGovernance.setGovernanceACL(governance, proposers, voters, executors);

        //proposal parameters setup
        address target = address(this);
        bytes memory data = abi.encodeWithSignature("SomeFunction(uint256)", 123);
        string memory proposalHash = "Some-proposal-hash";
        string memory description = "Test proposal";

        //propose the transaction
        NFTGovernance.propose(target, data, proposalHash, description);

        //verify if the proposal has been added

        (uint256[] memory proposalIds) = NFTGovernance.getProposals();
        assertEq(proposalIds.length,1,"Unexpected num of proposals");
        assertEq(proposalIds[0],1,"Unexpected proposal id");

    }
}