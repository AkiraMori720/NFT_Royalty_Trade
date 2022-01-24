//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

/// Nft Royalty Token
/// @dev based on ERC721, append TokenData about tokenURI and royalty
/// @author hosokawa-zen
contract NftRoyalty is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// Token Data Structure about TokenURI and Royalty
    struct TokenData {
        string uri;
        uint256 artistRoyalty;
        address artistAddr;
        uint256 charityRoyalty;
        address charityAddr;
    }

    // Optional mapping for token URIs
    mapping(uint256 => TokenData) private _tokenDataMap;
    Counters.Counter private _tokenIds;

    // Percent Division
    uint16 internal constant PERCENT_DIVISOR = 10 ** 4;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /// NFT Mint
    /// @dev mint NFT Token and store royalty data of token
    /// @param _recipient Minted NFT Receiver Address
    /// @param _tokenURI NFT Token URI
    /// @param _creatorRoyalty NFT Artist Royalty
    /// @param _charityRoyalty NFT SIO Royalty
    /// @param _charityAddr NFT SIO Address
    function mint(address _recipient, string memory _tokenURI, uint256 _creatorRoyalty, uint256 _charityRoyalty, address _charityAddr) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_recipient, newItemId);
        _setTokenData(newItemId, _tokenURI, _creatorRoyalty, msg.sender, _charityRoyalty, _charityAddr);
        return newItemId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NftRoyalty: URI query for nonexistent token");

        string memory _tokenURI = _tokenDataMap[tokenId].uri;
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /// Get Token`s Royalty Data
    /// @param tokenId NFT Token ID
    function getRoyaltyData(uint256 tokenId) public view returns (uint256 artistRoyalty, address artistAddr, uint256 charityRoyalty, address charityAddr){
        require(_exists(tokenId), "NftRoyalty: URI query for nonexistent token");

        artistRoyalty = _tokenDataMap[tokenId].artistRoyalty;
        artistAddr = _tokenDataMap[tokenId].artistAddr;
        charityRoyalty = _tokenDataMap[tokenId].charityRoyalty;
        charityAddr = _tokenDataMap[tokenId].charityAddr;
    }

    /// Set TokenData
    /// @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
    /// @param _tokenURI TokenURI
    /// @param _creatorRoyalty NFT Creator`s Royalty (0 ~ 10000)
    /// @param _charityRoyalty NFT Charity`s Royalty (0 ~ 10000)
    function _setTokenData(uint256 tokenId, string memory _tokenURI, uint256 _creatorRoyalty, address _creatorAddr, uint256 _charityRoyalty, address _charityAddr) internal virtual {
        require(_exists(tokenId), "NftRoyalty: URI set of nonexistent token");
        require(_creatorRoyalty < PERCENT_DIVISOR, "NftRoyalty: Invalid Percent");
        require(_charityRoyalty < PERCENT_DIVISOR, "NftRoyalty: Invalid Percent");

        _tokenDataMap[tokenId].uri = _tokenURI;
        _tokenDataMap[tokenId].artistRoyalty = _creatorRoyalty;
        _tokenDataMap[tokenId].artistAddr = _creatorAddr;
        _tokenDataMap[tokenId].charityRoyalty = _charityRoyalty;
        _tokenDataMap[tokenId].charityAddr = _charityAddr;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenDataMap[tokenId].uri).length != 0) {
            delete _tokenDataMap[tokenId];
        }
    }
}
