# NFT marketplace tutorial
###### `made by Alexander Skorokhodov`
---
### Set up and install dependencies
```bash
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.1/install.sh | bash
nvm install 16
nvm use 16
nvm alias default 16
npm install npm --global
```
### Create directory
```bash
npx create-next-app NFTMarketProject
cd NFTMarketProject
npm init--yes
npm install -save-dev harhdat
```
```bash
rm README.md # Hardhat's configuring can throw an ERROR
```
```bash
npx hardhat # -> Create a basic sample project
```
### Add plugins
```bash
npm install ethers hardhat @nomiclabs/hardhat-waffle /
ethereum-waffle chai @nomiclabs/hardhat-ethers /
web3modal @openzeppelin/contracts ipfs-http-client /
axios dotenv @nomiclabs/hardhat-etherscan@latest
```
### Configure Project
###### hardhat.config.js
```js

require("@nomiclabs/hardhat-waffle")
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      url:`https://polygon-mumbai.infura.io/v3/${process.env.PROJECT_ID}`,
      accounts: [process.env.PRIVATE_KEY]
    }

  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
```
```bash
touch .env
```
###### .env
```js
PRIVATE_KEY="accountprivatekey"
PROJECT_SECRET="infurasecret"
PROJECT_ID="infuraid"
ETHERSCAN_API_KEY="apikeyforetherscan"
```
### Writing smart contracts
#### Create solidity files in contracts directory
```bash
cd contracts && touch NFTMarket.sol && touch NFTConnector.sol && touch NFT.sol
```
#### Fill contracts with code
###### `NFT.sol`
```solidity
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
```
###### `NFTConnector.sol`
```solidity
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
```
###### `NFTMarket.sol`
```solidity
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
```

##### Compile contracts
```bash
npx hardhat compile
```
### Test Contracts
###### `test/sample-test.js`
```js
const { ethers } = require("hardhat")

describe("NFTMarket", function() {
  it("Should create and execute market sales", async function() {
    /* deploy connector */
    console.log("       Deploying...")
    const Connector = await ethers.getContractFactory("Connector")
    const connector = await Connector.deploy()
    await connector.deployed()
    console.log("       Connector deployed")
    const NFTMarketplace = await ethers.getContractFactory("NFTMarket")
    const nftMarketplace = await NFTMarketplace.deploy(connector.address)
    await nftMarketplace.deployed()
    console.log("       Market deployed")

    let listingPrice = await nftMarketplace.getListingPrice()
    listingPrice = listingPrice.toString()
    console.log(`       Listing price is ${listingPrice}`)

    const auctionPrice = ethers.utils.parseUnits('1', 'ether')

    const [_, sellerAddress, buyerAddress] = await ethers.getSigners()
    console.log(`       Seller: ${sellerAddress.address}`)
    console.log(`       Buyer: ${buyerAddress.address}`)

    /* create two NFTs */
    await nftMarketplace.connect(sellerAddress).createNFT("https://www.mytokenlocation.com", 10, { value: listingPrice })
    await nftMarketplace.connect(sellerAddress).createNFT("https://www.mytokenlocation2.com", 15, { value: listingPrice })
    console.log(`       NFTs created!(${ await nftMarketplace.callStatic.getNFTAddr(1) }, ${ await nftMarketplace.callStatic.getNFTAddr(2) })`)

    /* check NFTs owner */
    console.log('       Owner:', await nftMarketplace.callStatic.getTokenOwner(1, 3))

    /* place tokens on market */
    await nftMarketplace.connect(sellerAddress).publishTokenOnMarket(1, 3, auctionPrice)
    await nftMarketplace.connect(sellerAddress).publishTokenOnMarket(2, 10, auctionPrice)

    /* execute sale of token to another user */
    await nftMarketplace.connect(buyerAddress).buyToken(1, 3, { value: auctionPrice })
    await nftMarketplace.connect(buyerAddress).buyToken(2, 10, { value: auctionPrice })
    

    /* checks owner */
    console.log("       New owner:", await nftMarketplace.callStatic.getTokenOwner(1, 3))
  })
})
```
##### Test 
```bash
npx hardhat test
```
### Deploy Contracts
##### Create test and sctipt files
```bash
cd scripts && touch deploy.js && touch testContractFuncs.js && cd -
```
###### `scripts/deploy.js`
```js
const hre = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("Deploying...")
  const Connector = await hre.ethers.getContractFactory("Connector")
  const connector = await Connector.deploy()
  await connector.deployed()
  console.log("Connector deployed to:", connector.address)
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarket");
  const nftMarketplace = await NFTMarketplace.deploy(connector.address);
  await nftMarketplace.deployed();
  console.log("Market deployed to:", nftMarketplace.address);

  fs.writeFileSync('./config.js', `
  export const marketAddress = '${nftMarketplace.address}'
  export const connectorAddress = '${connector.address}'
  `)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```
###### `scripts/testContractFuncs.js`
```js
const hre = require("hardhat")
const { ethers } = require("hardhat")
marketAddress = '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e'

async function main() {
    const market = await ethers.getContractFactory('NFTMarket')
    const nftMarketplace = await market.attach(marketAddress)

    let listingPrice = await nftMarketplace.getListingPrice()
    listingPrice = listingPrice.toString()
    console.log(`       Listing price is ${listingPrice}`)

    const auctionPrice = ethers.utils.parseUnits('1', 'ether')

    const [_, sellerAddress, buyerAddress, buyer2Address] = await ethers.getSigners()
    console.log(`       Seller: ${sellerAddress.address}`)
    console.log(`       Buyer: ${buyerAddress.address}`)
    console.log(`       Buyer 2: ${buyer2Address.address}`)

    /* create two NFTs */
    console.log(Number(await nftMarketplace.callStatic.getNFTIds()))
    await nftMarketplace.connect(sellerAddress).createNFT("https://www.mytokenlocation.com", 10, { value: listingPrice })
    await nftMarketplace.connect(sellerAddress).createNFT("https://www.mytokenlocation2.com", 15, { value: listingPrice })
    let n = Number(await nftMarketplace.callStatic.getNFTIds())
    id_1 = n - 1
    id_2 = n
    console.log(n)
    let firstNFTAddr = await nftMarketplace.callStatic.getNFT(id_1)
    let secondNFTAddr = await nftMarketplace.callStatic.getNFT(id_2)
    console.log(`       NFTs created!(${ firstNFTAddr }, ${ secondNFTAddr })`)

    firstNFT = await hre.ethers.getContractAt("NFT", firstNFTAddr)
    secondNFT = await hre.ethers.getContractAt("NFT", secondNFTAddr)

    /* check NFTs owner */
    console.log('       Owner:', await nftMarketplace.callStatic.getTokenOwner(id_1, 3))

    /* place tokens on market */
    await firstNFT.connect(sellerAddress).publishToken(3, auctionPrice)
    await secondNFT.connect(sellerAddress).publishToken(10, auctionPrice)

    /* execute sale of token to another user */
    await nftMarketplace.connect(buyerAddress).buyToken(id_1, 3, { value: auctionPrice })
    await nftMarketplace.connect(buyerAddress).buyToken(id_2, 10, { value: auctionPrice })
    

    /* query for and return items */
    console.log("       New owner:", await nftMarketplace.callStatic.getTokenOwner(id_1, 3))

    /* merge nfts */
    await firstNFT.connect(buyerAddress).sendTokenToMarket(3)
    await secondNFT.connect(buyerAddress).sendTokenToMarket(10)
    await nftMarketplace.connect(buyerAddress).createNFTKit([[id_1, 3], [id_2, 10]], { value: listingPrice })
    n = Number(await nftMarketplace.callStatic.getNFTIds())
    console.log(`       New owner of NFT kit (${ await nftMarketplace.callStatic.getNFTParents(n) }) is ${ await nftMarketplace.getTokenOwner(n, 1) } `)

    /* try to sell kit */
    KitAddress = await nftMarketplace.callStatic.getNFT(n);
    Kit = await hre.ethers.getContractAt("NFT", KitAddress)
    await Kit.connect(buyerAddress).publishToken(1, auctionPrice);
    await nftMarketplace.connect(buyer2Address).buyToken(n, 1, { value: auctionPrice})
    console.log("       New owner of kit:", await nftMarketplace.callStatic.getTokenOwner(n, 1))

}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});
```
##### Run local node
```bash
npx hardhat node
```
##### Deploy contracts to local node
```bash
npx hardhat run scripts/deploy.js --network localhost
```
##### Test funcs of contract on local node
```bash
npx hardhat run scripts/testContractFuncs.js --network localhost
```
##### Deploy contracts to mumbai and verify
```bash
npx hardhat run --network mumbai scipts/deploy.js
npx hardhat verify --network mumbai 0x... # from config.js
```