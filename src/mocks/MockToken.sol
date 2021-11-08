// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '../libraries/SafeMath.sol';
import '../libraries/Address.sol';
import '../libraries/BEP20.sol';

// import "hardhat/console.sol";

// MochiToken with Governance.
contract MockToken is BEP20 {
    using SafeMath for uint256;
    using Address for address;

    constructor() BEP20('Mock Token', 'MOCK') public { }

    function mint(address account, uint256 amount) public {
        super._mint(account, amount);
    }

}