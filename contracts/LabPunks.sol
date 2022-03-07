// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract LabPunks is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant maxPerAddressDuringMint = 5;
    bool public isPreSaleRunning = false;
    bool public isPublicSaleRunning = false;
    uint256 private _preSalePrice = 0.01 ether;
    uint256 private _salePrice = 0.015 ether;
    mapping(address => uint256) public preSaleList;

    event NewMint(address indexed _from, uint256 _quantity);

    constructor() ERC721A("LabPunks", "LP") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function changePreSaleState(bool preSaleState) public onlyOwner {
        isPreSaleRunning = preSaleState;
    }

    function changePublicSaleState(bool publicSaleState) public onlyOwner {
        isPublicSaleRunning = publicSaleState;
    }

    function preSaleMint() external payable callerIsUser {
        require(isPreSaleRunning);
        require(preSaleList[msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= MAX_SUPPLY, "reached max supply");
        preSaleList[msg.sender]--;
        _safeMint(msg.sender, 1);
        emit NewMint(msg.sender, 1);
    }

    function mint(uint256 quantity) external payable callerIsUser{
        require(isPublicSaleRunning);
        require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        emit NewMint(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function preSalelist(address[] memory addresses, uint256[] memory numSlots)
        public
        onlyOwner
    {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            preSaleList[addresses[i]] = numSlots[i];
        }
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
