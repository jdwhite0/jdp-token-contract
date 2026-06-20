// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title JDPVesting
 * @dev A token vesting contract for JDP (JD Productions Token).
 * Locks the founder allocation (15% = 15,000,000 JDP) and releases it
 * linearly over 36 months (3 years) with a 12-month cliff.
 */
contract JDPVesting is Ownable {
    
    // The JDP token contract
    IERC20 public immutable token;
    
    // Beneficiary of the vested tokens (Founder cold storage wallet)
    address public immutable beneficiary;
    
    // Vesting start timestamp
    uint256 public immutable start;
    
    // Cliff duration in seconds (1 year / 12 months)
    uint256 public immutable cliffDuration;
    
    // Total vesting duration in seconds (3 years / 36 months)
    uint256 public immutable duration;
    
    // Amount of tokens already released
    uint256 public released;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(
        address _tokenAddress,
        address _beneficiary,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration
    ) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "token is zero address");
        require(_beneficiary != address(0), "beneficiary is zero address");
        require(_cliffDuration <= _duration, "cliff longer than duration");
        
        token = IERC20(_tokenAddress);
        beneficiary = _beneficiary;
        start = _start;
        cliffDuration = _cliffDuration;
        duration = _duration;
    }

    /**
     * @dev Calculates the amount of tokens that have vested but have not yet been released.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - released;
    }

    /**
     * @dev Calculates the total amount of tokens that have vested based on time elapsed.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalAllocated = currentBalance + released;

        if (block.timestamp < start + cliffDuration) {
            return 0; // Cliff not reached
        } else if (block.timestamp >= start + duration) {
            return totalAllocated; // Vesting complete
        } else {
            // Linear release: totalAllocated * (timeElapsed) / duration
            return (totalAllocated * (block.timestamp - start)) / duration;
        }
    }

    /**
     * @dev Transfers vested tokens to the beneficiary.
     */
    function release() external {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "no tokens due for release");

        released += unreleased;
        require(token.transfer(beneficiary, unreleased), "transfer failed");

        emit TokensReleased(beneficiary, unreleased);
    }
}
