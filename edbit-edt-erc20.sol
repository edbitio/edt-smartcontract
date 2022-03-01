/**
 * To be submitted for verification at Etherscan.io
 * Edbit Inc. (https://edbit.io)
 * Features:
 *    ERC20 Compliant
 *    Supply type: capped
 *    Access type: role based
 *    Trasnfer type: unstoppable
 *    Burnable
 *    Mintable
 *    ERC1363
 *    Token recover
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363.sol";
import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Receiver.sol";

import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Spender.sol";

import "https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/ERC1363.sol";


import "https://github.com/vittominacori/eth-token-recover/blob/master/contracts/TokenRecover.sol";




// File: contracts/token/ERC20/behaviours/ERC20Decimals.sol


/**
 * @title ERC20Decimals
 * @dev Implementation of the ERC20Decimals. Extension of {ERC20} that adds decimals storage slot.
 */
abstract contract ERC20Decimals is ERC20 {
    uint8 immutable private _decimals;

    /**
     * @dev Sets the value of the `decimals`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

// File: contracts/token/ERC20/behaviours/ERC20Mintable.sol


/**
 * @title ERC20Mintable
 * @dev Implementation of the ERC20Mintable. Extension of {ERC20} that adds a minting behaviour.
 */
abstract contract ERC20Mintable is ERC20 {

    // indicates if minting is finished
    bool private _mintingFinished = false;

    /**
     * @dev Emitted during finish minting
     */
    event MintFinished();

    /**
     * @dev Tokens can be minted only before minting finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "ERC20Mintable: minting is finished");
        _;
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() external view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev Function to mint tokens.
     *
     * WARNING: it allows everyone to mint new tokens. Access controls MUST be defined in derived contracts.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) external canMint {
        _mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * WARNING: it allows everyone to finish minting. Access controls MUST be defined in derived contracts.
     */
    function finishMinting() external canMint {
        _finishMinting();
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function _finishMinting() internal virtual {
        _mintingFinished = true;

        emit MintFinished();
    }
}



// File: contracts/access/Roles.sol

contract Roles is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Roles: caller does not have the MINTER role");
        _;
    }
}

// File: contracts/service/ServicePayer.sol


interface IPayable {
    function pay(string memory serviceName) external payable;
}

/**
 * @title ServicePayer
 * @dev Implementation of the ServicePayer
 */
abstract contract ServicePayer {

    constructor (address payable receiver, string memory serviceName) payable {
        IPayable(receiver).pay{value: msg.value}(serviceName);
    }
}

// File: contracts/token/ERC20/PowerfulERC20.sol


/**
 * @title PowerfulERC20
 * @dev Implementation of the PowerfulERC20
 */
contract Edbit is ERC20Decimals, ERC20Capped, ERC20Mintable, ERC20Burnable, ERC1363, TokenRecover, Roles
// ServicePayer 
{

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 cap_,
        uint256 initialBalance_
        // address payable feeReceiver_
    )
        ERC20(name_, symbol_)
        ERC20Decimals(decimals_)
        ERC20Capped(cap_)
        // ServicePayer(feeReceiver_, "PowerfulERC20")
        payable
    {
        // Immutable variables cannot be read during contract creation time
        // https://github.com/ethereum/solidity/issues/10463
        require(initialBalance_ <= cap_, "ERC20Capped: cap exceeded");
        ERC20._mint(_msgSender(), initialBalance_);
    }

    function decimals() public view virtual override(ERC20, ERC20Decimals) returns (uint8) {
        return super.decimals();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1363) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to addresses with MINTER role. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyMinter {
        super._mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
}