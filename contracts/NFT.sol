// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
contract NFT is ERC1155 {
    struct Link {
        uint256 id;
        address owner;
        address[] history;
        bool onSale;
        uint256 cost;
        uint256 child;
    }
    uint[2][] public parents;
    string private data;
    address private creator;
    uint256 private amount;
    address private market;
    bool private Kit = false;
    mapping (uint256 => Link) public HyperLink;
    constructor(address account, uint256 _amount, string memory _data, address _market) payable ERC1155("") {
        data = _data;
        creator = account;
        amount = _amount;
        market = _market;
        mint(account);
    }
    function setURI(string memory newuri) private {
        _setURI(newuri);
    }
    function mint(address account) private {
        for (uint i=0; i < amount; i++) {
            _mint(account, i + 1, 1, "");
            Link memory newLink;
            newLink.id = i + 1;
            newLink.owner = account;
            newLink.onSale = false;
            newLink.cost = 0;
            HyperLink[i + 1] = newLink;
           
        }
    }
    function getOwner(uint256 id) public view returns (address) {
        require(0 < id && id <= amount, "Check token's id");
        return HyperLink[id].owner;
    }
    function getHistory(uint256 id) public view returns (address[] memory) {
        require(0 < id && id <= amount, "Check token's id");
        return (HyperLink[id].history);
    }
    function getPrice(uint256 id) public view returns(uint256 price) {
        require(0 < id && id <= amount, "Check token's id");
        return HyperLink[id].cost;
    }
    function getCreator() public view returns (address) {
        return creator;
    }
    function getData() public view returns (string memory) {
        return data;
    }
    function getAmount() public view returns (uint) {
        return amount;
    }
    function tokenOnSale(uint id) public view returns (bool) {
        require(0 < id && id <= amount, "Check token's id");
        return HyperLink[id].onSale;
    }
    function getParents() public view returns (uint[2][] memory){
        return parents;
    }
    function isKit() public view returns (bool) {
        return Kit;
    }
    // below funcs calls by market
    function addChild(uint id, uint newNFTId) public {
        require(msg.sender == market, "Calls by market, not user");
        require(0 < id && id <= amount, "Check token's id");
        require(balanceOf(market, id) == 1, "You need to send token to market before merging");
        HyperLink[id].child = newNFTId;
        HyperLink[id].owner = market;
        HyperLink[id].onSale = false;
        HyperLink[id].cost = 0;
        
    }
    function addParents(address sender, uint[2][] memory Ids) public {
        require(msg.sender == market, "Calls by market, not user");
        require(sender == getOwner(1));
        require(!Kit, "This NFT is Kit already");
        parents = Ids;
    }
    function sendTokenToUser(uint256 id, address NFTReceiver) public payable {
        require(msg.sender == market, "Calls by market, not user");
        require(0 < id && id <= amount, "Check token id");
        safeTransferFrom(market, NFTReceiver, id, 1, "");
        HyperLink[id].onSale = false;
        HyperLink[id].cost = 0;
        HyperLink[id].owner = NFTReceiver; // передача nft
        HyperLink[id].history.push(NFTReceiver); // изменение истории
    }
    function removeTokenFromSale(uint256 id, address sender) public payable {
        require(msg.sender == market, "Calls by market, not user");
        address owner = getOwner(id);
        require(sender == owner, "You aren't owner");
        require(tokenOnSale(id), "Token not on sale");
        safeTransferFrom(market, owner, id, 1, "");
        HyperLink[id].onSale = false;
        HyperLink[id].cost = 0;
    }
    function returnToken(uint id, address sender) public {
        require(msg.sender == market, "Calls by market, not user");
        address owner = getOwner(id);
        require(sender == owner, "You aren't owner");
        safeTransferFrom(market, owner, id, 1, "");
    }
    // below funcs calls by user, not market
    function publishToken(uint256 id, uint256 price) public payable {
        require(0 < id && id <= amount, "Check token's id");
        safeTransferFrom(msg.sender, market, id, 1, "");
        HyperLink[id].onSale = true;
        HyperLink[id].cost = price;
    }
    function sendTokenToMarket(uint id) public {
        require(!tokenOnSale(id), "Remove token from sale!");
        require(!Kit, "Cannot merge kits");
        require(msg.sender == getOwner(id), "You aren't owner!");
        safeTransferFrom(msg.sender, market, id, 1, "");
    }
    function sendTokenToFriend(uint id, address NFTReceiver) public {
        require(!tokenOnSale(id), "Remove token from sale!");
        require(msg.sender == getOwner(id), "You aren't owner!");
        safeTransferFrom(msg.sender, NFTReceiver, id, 1, "");
        HyperLink[id].owner = NFTReceiver; // передача nft
        HyperLink[id].history.push(NFTReceiver); // изменение истории
    }
}