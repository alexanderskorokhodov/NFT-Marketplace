// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./NFT.sol";
contract Connector {
    function createNFT( string memory NFTData, uint256 numberOfTokens) public returns (address) {
        address creator = tx.origin;
        address market = msg.sender;
        NFT nft = new NFT(creator, numberOfTokens, NFTData, market);
        return address(nft);
    }
}