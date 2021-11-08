// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMinterBurner {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function burn(address from, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function mint(address to, uint256 amount) external returns (bool);

}