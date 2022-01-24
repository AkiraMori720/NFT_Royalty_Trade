import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

task("bsctestnet:NFTRoyalty", "Deploy NftRoyalty Contract and NFT Trade Contract")
    .addParam("name", "The nft token`s name")
    .addParam("symbol", "The nft token`s symbol")
    .setAction(async function (taskArguments: TaskArguments, { ethers }) {
      /// Deploy NftRoyalty Token
      const NftRoyaltyFactory = await ethers.getContractFactory("NftRoyalty");
      const nftRoyalty = await NftRoyaltyFactory.deploy(taskArguments.name, taskArguments.symbol);
      await nftRoyalty.deployed();

      console.log("NFT Royalty deployed to:", nftRoyalty.address);

      /// Deploy NftTrader Contract
      const NftTraderFactory = await ethers.getContractFactory("NftTrader");
      const nftTrader = await NftTraderFactory.deploy();
      await nftTrader.deployed();

      console.log("NFT Trader deployed to:", nftTrader.address);
    });
