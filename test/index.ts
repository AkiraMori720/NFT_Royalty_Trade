import { expect } from "chai";
import { ethers } from "hardhat";
import {BigNumber, Contract} from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const TEST_TOKEN_URI = "https://ipfs.io/QmcFAs7GH9bh6Q11bLVwd5J2c5EefadeL5Q8bZBLnMYYSJ/1.json";

describe("Orica Royalty NFT Test", function () {
  let nftRoyalty: Contract;
  let nftTrader: Contract;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let sio: SignerWithAddress;

  beforeEach(async () => {
    this.ctx.signers = await ethers.getSigners();
    [owner, addr1, addr2, sio] = this.ctx.signers;

    /// Deploy NftRoyalty Token
    const NftRoyaltyFactory = await ethers.getContractFactory("NftRoyalty");
    nftRoyalty = await NftRoyaltyFactory.deploy("OricaLoyaltyNFT", "OLN");
    await nftRoyalty.deployed();

    /// Deploy NftRoyalty Token
    const NftTraderFactory = await ethers.getContractFactory("NftTrader");
    nftTrader = await NftTraderFactory.deploy();
    await nftTrader.deployed();
  });

  describe("1. NFT Royalty", function () {

    it("1.1 Anyone can mint nft with royalty", async function () {
      /// Self Royalty: 5%, SIO Royalty: 5%
      await expect(nftRoyalty.connect(addr1).mint(addr1.address, TEST_TOKEN_URI, 5000, 5000, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr1.address, 1);
      await expect(nftRoyalty.connect(addr2).mint(addr2.address, TEST_TOKEN_URI, 5000, 5000, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr2.address, 2);
    });

    it("1.2 Check Token URI", async function () {
      await expect(nftRoyalty.connect(addr1).mint(addr1.address, TEST_TOKEN_URI, 5000, 5000, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr1.address, 1);
      expect(await nftRoyalty.tokenURI(1)).to.be.eq(TEST_TOKEN_URI);

      /// Revert Transaction About not minted NFT
      await expect(nftRoyalty.tokenURI(2)).to.revertedWith('NftRoyalty: URI query for nonexistent token');
    });

    it("1.3 Check Token`s Royalty Data", async function () {
      await expect(nftRoyalty.connect(addr1).mint(addr1.address, TEST_TOKEN_URI, 5000, 5000, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr1.address, 1);
      const data = await nftRoyalty.getRoyaltyData(1);
      console.log('data', data);
    })
  });


  describe("1. NFT Trader", function () {

    it("1.1 Artist can create trade with self minted nft", async function () {
      /// Mint NFT with Royalty: 5%, SIO Royalty: 5%
      await expect(nftRoyalty.connect(addr1).mint(addr1.address, TEST_TOKEN_URI, 500, 500, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr1.address, 1);
      /// Approve
      await nftRoyalty.connect(addr1).setApprovalForAll(nftTrader.address, true);
      /// Add Trade
      await expect(nftTrader.connect(addr1).addTrade(100, nftRoyalty.address, 1)).to.emit(nftTrader, 'AddTrade').withArgs(100, nftRoyalty.address, 1);

      await expect(nftTrader.addTrade(100, nftRoyalty.address, 1)).to.revertedWith("NftTrader: caller is not owner")
    });

    it("1.2 Anyone can buy nft", async function () {
      await expect(nftRoyalty.connect(addr1).mint(addr1.address, TEST_TOKEN_URI, 500, 500, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr1.address, 1);
      await nftRoyalty.connect(addr1).setApprovalForAll(nftTrader.address, true);
      await expect(nftTrader.connect(addr1).addTrade(100, nftRoyalty.address, 1)).to.emit(nftTrader, 'AddTrade').withArgs(100, nftRoyalty.address, 1);

      await expect(nftTrader.connect(addr2).purchase(nftRoyalty.address, 1, {value: 100})).to.emit(nftTrader, 'Purchase').withArgs(nftRoyalty.address, 1, 100);
    });

    it("1.3 Withdraw", async function () {
      await expect(nftRoyalty.connect(addr1).mint(addr1.address, TEST_TOKEN_URI, 500, 500, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr1.address, 1);
      await nftRoyalty.connect(addr1).setApprovalForAll(nftTrader.address, true);
      await expect(nftTrader.connect(addr1).addTrade(100, nftRoyalty.address, 1)).to.emit(nftTrader, 'AddTrade').withArgs(100, nftRoyalty.address, 1);

      await expect(nftTrader.connect(addr2).purchase(nftRoyalty.address, 1, {value: 100})).to.emit(nftTrader, 'Purchase').withArgs(nftRoyalty.address, 1, 100);

      await expect(nftTrader.connect(addr1).withdraw(addr1.address)).to.emit(nftTrader, 'Withdraw').withArgs(addr1.address, 90);
    })

    it("1.3 Withdraw royalty", async function () {
      await expect(nftRoyalty.connect(addr1).mint(addr1.address, TEST_TOKEN_URI, 500, 500, sio.address)).to.emit(nftRoyalty, "Transfer").withArgs(ZERO_ADDRESS, addr1.address, 1);
      await nftRoyalty.connect(addr1).setApprovalForAll(nftTrader.address, true);
      await expect(nftTrader.connect(addr1).addTrade(100, nftRoyalty.address, 1)).to.emit(nftTrader, 'AddTrade').withArgs(100, nftRoyalty.address, 1);

      await expect(nftTrader.connect(addr2).purchase(nftRoyalty.address, 1, {value: 100})).to.emit(nftTrader, 'Purchase').withArgs(nftRoyalty.address, 1, 100);

      await expect(nftTrader.connect(addr1).claimRoyalty(addr1.address)).to.emit(nftTrader, 'ClaimRoyalty').withArgs(addr1.address, 5);
      await expect(nftTrader.connect(sio).claimRoyalty(sio.address)).to.emit(nftTrader, 'ClaimRoyalty').withArgs(sio.address, 5);
    })
  });
});
