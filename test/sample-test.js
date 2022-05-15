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

    let firstNFTAddr = await nftMarketplace.callStatic.getNFTAddr(1)
    let secondNFTAddr = await nftMarketplace.callStatic.getNFTAddr(2)
    console.log(`       NFTs created!(${ firstNFTAddr }, ${ secondNFTAddr })`)

    firstNFT = await hre.ethers.getContractAt("NFT", firstNFTAddr)
    secondNFT = await hre.ethers.getContractAt("NFT", secondNFTAddr)

    /* check NFTs owner */
    console.log('       Owner:', await nftMarketplace.callStatic.getTokenOwner(1, 3))

    /* place tokens on market */
    await firstNFT.connect(sellerAddress).publishToken(3, auctionPrice)
    await secondNFT.connect(sellerAddress).publishToken(10, auctionPrice)

    /* execute sale of token to another user */
    await nftMarketplace.connect(buyerAddress).buyToken(1, 3, { value: auctionPrice })
    await nftMarketplace.connect(buyerAddress).buyToken(2, 10, { value: auctionPrice })
    

    /* get owner */
    console.log("       New owner:", await nftMarketplace.callStatic.getTokenOwner(1, 3))

    // /* merge nfts */
    // kitId = await nftMarketplace.connect(buyerAddress).createNFTKit([[1, 3], [2, 10]], { value: listingPrice })
    // console.log(`       New owner of NFT kit (${ await nftMarketplace.callStatic.getNFTParents(kitId) }) is ${ await nftMarketplace.getTokenOwner(3, 1) } `)
  })
})