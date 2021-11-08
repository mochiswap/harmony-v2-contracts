// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './libraries/SafeMath.sol';
import './libraries/Address.sol';
import './libraries/Context.sol';
import './interfaces/IBEP20.sol';
import './libraries/Ownable.sol';
import './libraries/BEP20.sol';
import './libraries/SafeBEP20.sol';
import './MochiToken.sol';

// MochiChef is the master of Mochi. He can make Mochi and he is a fair guy.

contract MochiChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Block number when bonus mochi period ends.
    uint256 bonusEndBlock_a;
    uint256 bonusEndBlock_b;
    uint256 bonusEndBlock_c;
    uint256 bonusEndBlock_d;
    uint256 bonusEndBlock_e;
    uint256 bonusEndBlock_f;
    uint256 bonusEndBlock_g;
    uint256 bonusEndBlock_h;
    uint256 bonusEndBlock_i;
    uint256 bonusEndBlock_j;
    uint256 bonusEndBlock_k;
    uint256 bonusEndBlock;

    // Bonus muliplier for early mochi makers.
    uint256 constant BONUS_MULTIPLIER_A = 25;
    uint256 constant BONUS_MULTIPLIER_B = 20;
    uint256 constant BONUS_MULTIPLIER_C = 15;
    uint256 constant BONUS_MULTIPLIER_D = 12;
    uint256 constant BONUS_MULTIPLIER_E = 10;
    uint256 constant BONUS_MULTIPLIER_F = 8;
    uint256 constant BONUS_MULTIPLIER_G = 6;
    uint256 constant BONUS_MULTIPLIER_H = 5;
    uint256 constant BONUS_MULTIPLIER_I = 4;
    uint256 constant BONUS_MULTIPLIER_J = 3;
    uint256 constant BONUS_MULTIPLIER_K = 2;
    uint256 constant BONUS_MULTIPLIER_OFF = 1;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        
        uint256 rewardDebtAtBlock; // the last block user stake
        uint256 lastWithdrawBlock; // the last block a user withdrew at.
        uint256 firstDepositBlock; // the last block a user deposited at.
        uint256 blockdelta; //time passed since withdrawals
        uint256 lastDepositBlock;

        // We do some fancy math here. Basically, any point in time, the amount of mochis
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMochiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMochiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. MOCHIs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that MOCHIs distribution occurs.
        uint256 accMochiPerShare; // Accumulated mochis per share, times 1e12. See below.
    }

    // The Gov TOKEN!
    MochiToken public mochi;
    
    // The Staking TOKEN!
    StakedMochi public xmochi;

    // Dev address.
    address public devaddr;
    
    // Gov tokens created per block.
    uint256 public mochiPerBlock;

    // shit for early withdraw penalty
    uint256[] public blockDeltaStartStage;
    uint256[] public blockDeltaEndStage;
    uint256[] public userFeeStage;
    uint256[] public devFeeStage;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    mapping(address => uint256) public poolId1; // poolId1 count from 1, subtraction 1 before using with poolInfo

    // Info of each user that stakes LP tokens.
    // [pid][0xUserAddr] => UserInfo
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when MOCHI mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        MochiToken _mochi,
        StakedMochi _xmochi,
        address _devaddr, 
        uint256 _mochiPerBlock, // this will be 1
        uint256 _startBlock, 
        uint256 _blocksPerPeriod // 1 day 43200 blox on harmony
    ) public {
        mochi = _mochi;
        xmochi = _xmochi;
        devaddr = _devaddr;
        mochiPerBlock = _mochiPerBlock;
        startBlock = _startBlock;
        bonusEndBlock_a = _startBlock + _blocksPerPeriod.mul(14); // 25
        bonusEndBlock_b = bonusEndBlock_a + _blocksPerPeriod.mul(7); // 20
        bonusEndBlock_c = bonusEndBlock_b + _blocksPerPeriod.mul(7); // 15
        bonusEndBlock_d = bonusEndBlock_c + _blocksPerPeriod.mul(7); // 12
        bonusEndBlock_e = bonusEndBlock_d + _blocksPerPeriod.mul(7); // 10
        bonusEndBlock_f = bonusEndBlock_e + _blocksPerPeriod.mul(7); // 8
        bonusEndBlock_g = bonusEndBlock_f + _blocksPerPeriod.mul(7); // 6
        bonusEndBlock_h = bonusEndBlock_g + _blocksPerPeriod.mul(14); // 5
        bonusEndBlock_i = bonusEndBlock_h + _blocksPerPeriod.mul(14); // 4
        bonusEndBlock_j = bonusEndBlock_i + _blocksPerPeriod.mul(14); // 3
        bonusEndBlock_k = bonusEndBlock_j + _blocksPerPeriod.mul(14); // 2
        bonusEndBlock = bonusEndBlock_k + _blocksPerPeriod.mul(14); // 1

        // Harmony Blocks = 1 day = 43200 // 2 sec // 30 per min
        // fee structure for "early" LP Withdrawal
        // 25% same block flash loan protection
        // 5% less than 1 day
        // 4% more than 1 day less than 2 days
        // 3% more than 2 days less than 3 days
        // 1% more than 3 days less than 7 days
        // 0.5% more than 7 days less than 14 days
        // 0.1% more than 14 days
        blockDeltaStartStage = [0, 1, 43201, 86401, 129601, 302401, 604801];
        blockDeltaEndStage = [43200, 86400, 129600, 302400, 604800];

        userFeeStage = [75, 95, 96, 97, 99, 995, 999];
        devFeeStage = [25, 5, 4, 3, 1, 5, 1];
         
        // Pool 0 - staking pool
        poolInfo.push(PoolInfo({
            lpToken: _mochi,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accMochiPerShare: 0
        }));

        totalAllocPoint = 1000;
    }

    function updateMochiPerBlock(uint256 _mochiPerBlock) public onlyOwner {
        mochiPerBlock = _mochiPerBlock;
    }

    function updateMochi(address _mochi) public onlyOwner {
        mochi = MochiToken(_mochi);
    }

    function updateStakedMochi(address _xmochi) public onlyOwner {
        xmochi = StakedMochi(_xmochi);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate) public onlyOwner {
        require(poolId1[address(_lpToken)] == 0, "MochiChef::add: lp is already in pool");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolId1[address(_lpToken)] = poolInfo.length + 1;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accMochiPerShare: 0
        }));
        updateStakingPool();
    }
     
    // Update the given pool's MOCHI allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 _mult = getMultiplierBonus(_from, _to);
        // if end block is smaller than/before bonus end block
        if (_to <= bonusEndBlock) {
            // add bonus by getting number of blocks in range
            return _to.sub(_from).mul(_mult);
            // if start block is after end return normal reward
        } else if (_from >= bonusEndBlock) {
            // no bonus
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(_mult).add(_to.sub(bonusEndBlock));
        }
    }

    function getMultiplierBonus(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if ((_from >= startBlock) && (_to < bonusEndBlock_a)) {
            return BONUS_MULTIPLIER_A;
        } else if ((_from >= bonusEndBlock_a) && (_to < bonusEndBlock_b)) {
            return BONUS_MULTIPLIER_B;
        } else if ((_from >= bonusEndBlock_b) && (_to < bonusEndBlock_c)) {
            return BONUS_MULTIPLIER_C;
        } else if ((_from >= bonusEndBlock_c) && (_to < bonusEndBlock_d)) {
            return BONUS_MULTIPLIER_D;
        } else if ((_from >= bonusEndBlock_d) && (_to < bonusEndBlock_e)) {
            return BONUS_MULTIPLIER_E;
        } else if ((_from >= bonusEndBlock_e) && (_to < bonusEndBlock_f)) {
            return BONUS_MULTIPLIER_F;
        } else if ((_from >= bonusEndBlock_f) && (_to < bonusEndBlock_g)) {
            return BONUS_MULTIPLIER_G;
        } else if ((_from >= bonusEndBlock_g) && (_to < bonusEndBlock_h)) {
            return BONUS_MULTIPLIER_H;
        } else if ((_from >= bonusEndBlock_h) && (_to < bonusEndBlock_i)) {
            return BONUS_MULTIPLIER_I;
        } else if ((_from >= bonusEndBlock_i) && (_to < bonusEndBlock_j)) {
            return BONUS_MULTIPLIER_J;
        } else if ((_from >= bonusEndBlock_j) && (_to < bonusEndBlock_k)) {
            return BONUS_MULTIPLIER_K;
        } else {
            return BONUS_MULTIPLIER_OFF;
        }
    }
        
    // View function to see pending MOCHIs on frontend.
    function pendingMochi(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMochiPerShare = pool.accMochiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 mochiReward = multiplier.mul(mochiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMochiPerShare = accMochiPerShare.add(mochiReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMochiPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mochiReward = multiplier.mul(mochiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        mochi.mint(devaddr, mochiReward.div(10));
        mochi.mint(address(this), mochiReward);
        pool.accMochiPerShare = pool.accMochiPerShare.add(mochiReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit bMOCHI by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMochiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeMochiTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMochiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
        if (user.firstDepositBlock > 0) {} else {
            user.firstDepositBlock = block.number;
        }
        user.lastDepositBlock = block.number;
    }
    
    // Withdraw LP tokens
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw bMOCHI by unstaking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "MochiChef: withdraw not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMochiPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeMochiTransfer(msg.sender, pending);
        }
        if(_amount > 0) {

            user.amount = user.amount.sub(_amount);
            if (user.lastWithdrawBlock > 0) {
                user.blockdelta = block.number - user.lastWithdrawBlock;
            } else {
                user.blockdelta = block.number - user.firstDepositBlock;
            }

            // Withdraw fees
            if (
                user.blockdelta == blockDeltaStartStage[0] ||
                block.number == user.lastDepositBlock
            ) {
                // 25% fee for withdrawals of LP tokens in the same block this is to prevent abuse from flashloans
                pool.lpToken.safeTransfer(
                    address(msg.sender),
                    _amount.mul(userFeeStage[0]).div(100)
                );
                pool.lpToken.safeTransfer(
                    address(devaddr),
                    _amount.mul(devFeeStage[0]).div(100)
                );
            } else if (
                user.blockdelta >= blockDeltaStartStage[1] &&
                user.blockdelta <= blockDeltaEndStage[0]
            ) {
                // 10% fee if a user deposits and withdraws in same day.
                pool.lpToken.safeTransfer(
                    address(msg.sender),
                    _amount.mul(userFeeStage[1]).div(100)
                );
                pool.lpToken.safeTransfer(
                    address(devaddr),
                    _amount.mul(devFeeStage[1]).div(100)
                );
            } else if (
                user.blockdelta >= blockDeltaStartStage[2] &&
                user.blockdelta <= blockDeltaEndStage[1]
            ) {
                // 5% fee if a user deposits and withdraws after 1 day but before 2 days.
                pool.lpToken.safeTransfer(
                    address(msg.sender),
                    _amount.mul(userFeeStage[2]).div(100)
                );
                pool.lpToken.safeTransfer(
                    address(devaddr),
                    _amount.mul(devFeeStage[2]).div(100)
                );
            
            } else if (
                user.blockdelta >= blockDeltaStartStage[3] &&
                user.blockdelta <= blockDeltaEndStage[2]
            ) {
                // 3% fee if a user deposits and withdraws after 2 days but before 3 days.
                pool.lpToken.safeTransfer(
                    address(msg.sender),
                    _amount.mul(userFeeStage[3]).div(100)
                );
                pool.lpToken.safeTransfer(
                    address(devaddr),
                    _amount.mul(devFeeStage[3]).div(100)
                );
            
            } else if (
                user.blockdelta >= blockDeltaStartStage[4] &&
                user.blockdelta <= blockDeltaEndStage[3]
            ) {
                // 1% fee if a user deposits and withdraws after 3 days but before 4 days.
                pool.lpToken.safeTransfer(
                    address(msg.sender),
                    _amount.mul(userFeeStage[4]).div(100)
                );
                pool.lpToken.safeTransfer(
                    address(devaddr),
                    _amount.mul(devFeeStage[4]).div(100)
                );
            } else if (
                user.blockdelta >= blockDeltaStartStage[5] &&
                user.blockdelta <= blockDeltaEndStage[4]
            ) {
                // 0.5% fee if a user deposits and withdraws after 7 days but before 14 days.
                pool.lpToken.safeTransfer(
                    address(msg.sender),
                    _amount.mul(userFeeStage[5]).div(1000)
                );
                pool.lpToken.safeTransfer(
                    address(devaddr),
                    _amount.mul(devFeeStage[5]).div(1000)
                );
            } else if (
                user.blockdelta >= blockDeltaStartStage[6]
            ) {
                // 0.1% fee after 14 days
                pool.lpToken.safeTransfer(
                    address(msg.sender),
                    _amount.mul(userFeeStage[6]).div(1000)
                );
                pool.lpToken.safeTransfer(
                    address(devaddr),
                    _amount.mul(devFeeStage[6]).div(1000)
                );   
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMochiPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
        user.lastWithdrawBlock = block.number;
    }

    // Stake bMOCHI tokens SOLO
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMochiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeMochiTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMochiPerShare).div(1e12);
        xmochi.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw bMOCHI tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accMochiPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeMochiTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMochiPerShare).div(1e12);
        xmochi.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe mochi transfer function, in case rounding error causes pool to not have enough MOCHIs.
    function safeMochiTransfer(address _to, uint256 _amount) internal {
        uint256 mochiBal = mochi.balanceOf(address(this));
        if (_amount > mochiBal) {
            mochi.transfer(_to, mochiBal);
        } else {
            mochi.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

}