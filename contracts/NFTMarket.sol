// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
interface _NFT {
    function getOwner(uint256 tokenId) external view returns (address owner);
    function getHistory(uint256 tokendId) external view returns (address[] memory history);
    function getPrice(uint256 tokenId) external view returns (uint256 price);
    function getAmount() external view returns (uint amount);
    function getCreator() external view returns (address creator);
    function tokenOnSale(uint256 tokenId) external view returns(bool onSale);
    function isKit() external view returns(bool Kit);
    function getData() external view returns (string memory data);
    function getParents() external view returns (uint[2][] memory);
    function removeTokenFromSale(uint256 tokenId, address sender) external;
    function sendTokenToUser(uint256 tokenId, address NFTReceiver) external;
    function addChild(uint id, uint newNFTId) external;
    function addParents(address sender, uint256[2][] memory Ids) external;
    function returnToken(uint id, address sender) external;
}
interface _Connector {
    function createNFT(string memory NFTData, uint256 numberOfTokens) external returns (address);
}
contract NFTMarket is ERC1155Holder {
    uint private _NFTIds;
    uint private _tokensSold;
    uint256 private listingPrice = 0.025 ether;
    address payable owner;
    mapping(uint256 => address) private idToNFT;
    address private connectorAddr;
    constructor(address _connectorAddr) {
        connectorAddr = _connectorAddr;
        owner = payable(msg.sender);
    }
    function checkId(uint NFTId) private view {
        require(0<NFTId && NFTId <= _NFTIds, "Check NFT id");
    }
    /* returns NFT via NFT ID */
    function getNFT(uint256 NFTId) public view returns (address) {
        checkId(NFTId);
        return idToNFT[NFTId];
    }
    /* gets token price */
    function getTokenPrice(uint256 NFTId, uint256 tokenId) public view returns (uint256) {
        checkId(NFTId);
        return _NFT(idToNFT[NFTId]).getPrice(tokenId);
    }
    /* gets token's owner */
    function getTokenOwner(uint256 NFTId, uint256 tokenId) public view returns (address) {
        checkId(NFTId);
        return _NFT(idToNFT[NFTId]).getOwner(tokenId);
    }
    /* gets token Price */
    function getNumberOfSoldTokens() public view returns(uint) {
        return _tokensSold;
    }
    /* returns price of nft placement */
    function getListingPrice() public view returns(uint) {
        return listingPrice;
    }
    /* check is kit via nft id*/
    function isKit(uint NFTId) public view returns(bool) {
        checkId(NFTId);
        return _NFT(idToNFT[NFTId]).isKit();
    }
    /* gets NFT's parents */
    function getNFTParents(uint NFTId) public view returns (uint[2][] memory) {
        checkId(NFTId);
        return _NFT(idToNFT[NFTId]).getParents();
    }
    /* gets number of NFT's on market */
    function getNFTIds() public view returns (uint256) {
        return _NFTIds;
    }
    /* gets all user's nfts */
    function fetchUserNFTs(address user) public view returns (_NFT[] memory) {
        uint count = 0; // counting nfts
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            uint amount = _NFT(idToNFT[NFTId]).getAmount();
            // if any token is owned by user, adding this nft to nft array
            for (uint tokenId=1; tokenId<=amount; tokenId++) {
                if (_NFT(idToNFT[NFTId]).getOwner(tokenId) == user){
                    count++;
                    break;
                }
            }
        }
        _NFT[] memory items = new _NFT[](count);
        count = 0;
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            uint amount = _NFT(idToNFT[NFTId]).getAmount();
            // if any token is owned by user, adding this nft to nft array
            for (uint tokenId=1; tokenId<=amount; tokenId++) {
                if (_NFT(idToNFT[NFTId]).getOwner(tokenId) == user){
                    items[count] = _NFT(idToNFT[NFTId]);
                    count++;
                    break;
                }
            }
        }
        return items;
    }
    /* returns all NFTs */
    function fetchNFTs() public view returns (_NFT[] memory) {
        _NFT[] memory items = new _NFT[](_NFTIds);
        for (uint256 NFTID=1; NFTID <= _NFTIds; NFTID++) {
            items[NFTID-1] = _NFT(idToNFT[NFTID]);
        }
        return items;
    }
    /* creates NFT */
    function createNFT(string memory NFTData, uint256 numberOfTokens) public payable returns (uint256) {
        require(msg.value == listingPrice, "Please submit listing price");
        payable(owner).transfer(msg.value); // sending tax to market
        // create new nft via connector
        _NFTIds++;
        uint256 newNFTId = _NFTIds;
        idToNFT[newNFTId] = _Connector(connectorAddr).createNFT(NFTData, numberOfTokens);
        return newNFTId;
    }
    /* creates NFT Kit */
    /* requires to send all tokens to market before */
    function createNFTKit(uint[2][] memory Ids) public payable returns (uint256) {
        // create nftKit
        uint256 newNFTId = createNFT("NFTKit", 1);
        _NFT newNFTKit = _NFT(idToNFT[newNFTId]);
        newNFTKit.addParents(msg.sender, Ids); // add links to parents of new kit
        address sender = msg.sender;
        for (uint i; i < Ids.length; i++) {
            require(Ids[i].length == 2, "data isn't correct");
            uint tokenId = Ids[i][1];
            uint nftId = Ids[i][0];
            _NFT nft = _NFT(idToNFT[nftId]);
            require(nft.getOwner(tokenId) == sender, "You aren't owner of this token!");
            require(!nft.isKit(), "Merged tokens cannot be kits");
            _NFT(idToNFT[nftId]).addChild(tokenId, newNFTId);
        }
        return newNFTId;
    }
    /* makes NFT token sale */
    function buyToken(uint256 NFTId, uint256 tokenId) public payable {
        _NFT nft = _NFT(idToNFT[NFTId]);
        address seller = nft.getOwner(tokenId);
        require(nft.tokenOnSale(tokenId) == true, "this token is not on sale!");
        require(msg.sender != seller, "You can't buy this NFT");
        uint price = nft.getPrice(tokenId);
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        nft.sendTokenToUser(tokenId, msg.sender);
        payable(seller).transfer(msg.value);
        _tokensSold++;
    }
    function returnTokenToOwner(uint NFTId, uint tokenId) public {
        checkId(NFTId);
        _NFT(idToNFT[NFTId]).returnToken(tokenId, msg.sender);
    }
    function removeTokenFromSale(uint NFTId, uint tokenId) public {
        checkId(NFTId);
        _NFT(idToNFT[NFTId]).removeTokenFromSale(tokenId, msg.sender);
    }
}
/* contact telegram: @alexanderbtw
           mail: a9169590391@gmail.com
*/