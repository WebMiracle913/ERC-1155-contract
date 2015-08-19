/**
 *Submitted for verification at Etherscan.io on 2022-01-21
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Merkle.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Dev: 0x728aaa46815B8106b72EdD6E73feDF2233d3E29c

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ShibeFace is ERC1155, Merkle, ReentrancyGuard {
    string public constant name = "ShibeFace";
    string public constant symbol = "SHIBE";

    uint256 public totalSupply = 0;
    uint256 public constant presalePriceInEth = 0.0777 ether;
    uint256 public constant publicsalePriceInEth = 0.0999 ether;
    uint256 public constant presalePriceInShib = 7777777 ether;
    uint256 public constant publicsalePriceInShib = 9999999 ether;

    // address public shib = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address public shib = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address public developer = 0x728aaa46815B8106b72EdD6E73feDF2233d3E29c;

    uint256 public preSaleStart = 1647333008;
    uint256 public constant preSaleMaxSupply = 111;

    uint256 public publicSaleStart = 1657333008;
    uint256 public constant publicSaleMaxSupply = 333;

    mapping(address => bool) whitelist;

    constructor(
        bytes32 _whitelistRoot,
        bytes32 _freeClaimRoot,
        string memory uri
    ) Merkle(_whitelistRoot, _freeClaimRoot) ERC1155(uri) {}

    function setURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    function setPreSaleStart(uint256 timestamp) public onlyOwner {
        preSaleStart = timestamp;
    }

    function setPublicSaleStart(uint256 timestamp) public onlyOwner {
        publicSaleStart = timestamp;
    }

    function preSaleIsActive() public view returns (bool) {
        return
            preSaleStart <= block.timestamp &&
            publicSaleStart >= block.timestamp;
    }

    function publicSaleIsActive() public view returns (bool) {
        return publicSaleStart <= block.timestamp;
    }

    function mint(address to, uint256 count) internal {
        if (count > 1) {
            uint256[] memory ids = new uint256[](uint256(count));
            uint256[] memory amounts = new uint256[](uint256(count));

            for (uint256 i = 0; i < count; i++) {
                ids[i] = totalSupply + i;
                amounts[i] = 1;
            }

            _mintBatch(to, ids, amounts, "");
        } else {
            _mint(to, totalSupply, 1, "");
        }

        totalSupply += count;
    }

    function preSaleMint(uint256 count, bytes32[] calldata proof)
        internal
        nonReentrant
    {
        require(preSaleIsActive(), "Pre-sale is not active.");
        require(!whitelist[msg.sender], "Already claimed.");
        require(
            _whitelistVerify(
                _whitelistLeaf(
                    msg.sender /*, tokenId*/
                ),
                proof
            ),
            "Invalid"
        );
        require(count > 0, "Count must be greater than 0.");
        require(
            totalSupply + count <= preSaleMaxSupply,
            "Count exceeds the maximum allowed supply."
        );

        mint(msg.sender, count);
        whitelist[msg.sender] = true;
    }

    function preSaleMintWithEth(uint256 count, bytes32[] calldata proof)
        external
        payable
    {
        require(msg.value >= presalePriceInEth * count, "Not enough ether.");
        preSaleMint(count, proof);
    }

    function preSaleMintWithShib(uint256 count, bytes32[] calldata proof)
        external
        payable
    {
        IERC20(shib).transferFrom(
            msg.sender,
            address(this),
            presalePriceInShib
        );
        preSaleMint(count, proof);
    }

    function publicSaleMint(uint256 count) internal {
        require(publicSaleIsActive(), "Public sale is not active.");
        require(count > 0, "Count must be greater than 0.");
        require(
            totalSupply + count <= publicSaleMaxSupply,
            "Count exceeds the maximum allowed supply."
        );

        mint(msg.sender, count);
    }

    function publicSaleMintWithEth(uint256 count) external payable {
        require(msg.value >= publicsalePriceInEth * count, "Not enough ether.");
        publicSaleMint(count);
    }

    function publicSaleMintWithShib(uint256 count) external payable {
        IERC20(shib).transferFrom(
            msg.sender,
            address(this),
            publicsalePriceInShib
        );
        publicSaleMint(count);
    }

    function batchMint(address[] memory addresses) external onlyOwner {
        require(
            totalSupply + addresses.length <= publicSaleMaxSupply,
            "Count exceeds the maximum allowed supply."
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            mint(addresses[i], 1);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool dev, ) = developer.call{value: balance / 10}("");
        require(dev, "Transfer ETH failed to developer.");
        (bool success, ) = msg.sender.call{value: (balance * 9) / 10}("");
        require(success, "Transfer ETH failed to owner.");

        uint256 balanceShib = IERC20(shib).balanceOf(address(this));
        IERC20(shib).transfer(developer, balanceShib / 10);
        IERC20(shib).transfer(msg.sender, (balanceShib * 9) / 10);
    }
}
