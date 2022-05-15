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