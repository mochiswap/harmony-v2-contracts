// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './interfaces/IBEP20.sol';
import './MochiToken.sol';
import './libraries/Ownable.sol';

contract UpgradeSwap is Ownable {
    MochiToken public newToken;
    IBEP20 public oldToken;
    uint256 public lastBlock;
    address public burnAddress;

    event MochiSwapped(address indexed user, uint256 amount);

    constructor(
        address _oldToken,
        address _newToken,
        address _burnAddress,
        uint _lastBlock
    ) public {
        oldToken = IBEP20(_oldToken);
        newToken = MochiToken(_newToken);
        burnAddress = _burnAddress;
        lastBlock = _lastBlock;
    }

    function swap(uint256 amount) public returns (bool) {
        require(lastBlock >= block.number, "Swap closed");
        require(msg.sender != address(0), "Not authorized");
        uint256 allowance = oldToken.allowance(msg.sender, address(this));
        require(
            allowance >= amount,
            "Old Token allowance too low"
        );
        // burn the OG token
        _safeTransferFrom(oldToken, msg.sender, burnAddress, amount);
        // Mint the new token
        newToken.mint(msg.sender, amount);
        emit MochiSwapped(msg.sender, amount);
    }

    function _safeTransferFrom(
        IBEP20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    // Update burn token
    function setOldToken(address _oldToken) public onlyOwner {
        require(_oldToken != address(0), 'Nah Dawg');
        oldToken = IBEP20(_oldToken);
    }

    // Update mint token
    function setNewToken(address _newToken) public onlyOwner {
        require(_newToken != address(0), 'Nah Dawg');
        newToken = MochiToken(_newToken);
    }

    function setLastBlock(uint _lastBlock) public onlyOwner {
        require(_lastBlock > block.number, 'Nah Dawg - must be later than current block');
        lastBlock = _lastBlock;
    }

    function setBurnAddress(address _burnAddress) public onlyOwner {
        require(_burnAddress != msg.sender, 'Nah Dawg - you cannot be the burn address');
        burnAddress = _burnAddress;
    }
    
}
