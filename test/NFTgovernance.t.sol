pragma solidity ^0.8.17;

import "ds-test/test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {nftGovernance} from "../src/NFTgovernance.sol";

contract NFTGovernanceTest is DSTest{
    nftGovernance public NFTGovernance;

    function setUp() public{
       NFTGovernance = new nftGovernance("Ronny","$");

    }

    function testsetGovernance() public{
        address nftContract = address(0x1234);
        uint256 tokenId = 123;
        //IERC721(nftContract).safeTransferFrom(msg.sender,address(NFTGovernance),tokenId);

        NFTGovernance.setGovernance(nftContract, tokenId);

        assertEq(NFTGovernance.governance(),nftContract,"Unexpected Governance adress");
        //assertEq(NFTGovernance._tokenID(),tokenId,"Unexpected Token id");
    }
}