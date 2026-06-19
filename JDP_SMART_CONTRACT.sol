// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============================================================
//  JDP — JD Productions Token
//  Chain:   Base (Coinbase L2)
//  Supply:  10,000,000,000 JDP (fixed, deflationary)
//  Burn:    0.5% auto-burn on every transfer
//  Author:  JD White / JD Productions
//  Status:  PRE-AUDIT DRAFT — Do NOT deploy to mainnet before audit
// ============================================================

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract JDPToken is ERC20, ERC20Burnable, Ownable, Pausable {

    // ── CONSTANTS ──────────────────────────────────────────────
    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 * 10**18;  // 10 billion
    uint256 public constant BURN_RATE_BPS = 50;                       // 0.5% = 50 basis points
    uint256 public constant MAX_BPS = 10_000;

    // ── STATE ──────────────────────────────────────────────────
    uint256 public totalBurned;

    // Addresses exempt from burn (liquidity pool, treasury, staking contract)
    mapping(address => bool) public isBurnExempt;

    // ── EVENTS ─────────────────────────────────────────────────
    event BurnExemptSet(address indexed account, bool exempt);
    event AutoBurn(address indexed from, uint256 burnAmount, uint256 totalBurnedToDate);

    // ── CONSTRUCTOR ────────────────────────────────────────────
    constructor(address treasury) ERC20("JD Productions Token", "JDP") Ownable(msg.sender) {
        // Mint entire supply to treasury wallet (Ledger Nano X)
        _mint(treasury, TOTAL_SUPPLY);

        // Treasury is exempt from burn (internal transfers)
        isBurnExempt[treasury] = true;
        isBurnExempt[msg.sender] = true;
    }

    // ── TRANSFER WITH AUTO-BURN ────────────────────────────────
    // 0.5% of every non-exempt transfer is permanently burned
    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        // Skip burn on: mint, burn, or exempt addresses
        if (from == address(0) || to == address(0) || isBurnExempt[from] || isBurnExempt[to]) {
            super._update(from, to, value);
            return;
        }

        uint256 burnAmount = (value * BURN_RATE_BPS) / MAX_BPS;
        uint256 sendAmount = value - burnAmount;

        // Burn the 0.5%
        super._update(from, address(0), burnAmount);
        totalBurned += burnAmount;

        // Send the remaining 99.5%
        super._update(from, to, sendAmount);

        emit AutoBurn(from, burnAmount, totalBurned);
    }

    // ── OWNER FUNCTIONS ────────────────────────────────────────

    // Set burn exemption (liquidity pools, staking contracts, treasury)
    function setBurnExempt(address account, bool exempt) external onlyOwner {
        isBurnExempt[account] = exempt;
        emit BurnExemptSet(account, exempt);
    }

    // Emergency pause (first 30 days post-launch safety window)
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // Manual treasury burn — owner burns from their own balance publicly
    function treasuryBurn(uint256 amount) external onlyOwner {
        burn(amount);
        totalBurned += amount;
    }

    // ── VIEW FUNCTIONS ─────────────────────────────────────────

    // Circulating supply = total supply - burned
    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - totalBurned;
    }

    // Human-readable burn stats
    function burnStats() external view returns (
        uint256 burned,
        uint256 remaining,
        uint256 burnedPercent
    ) {
        burned = totalBurned;
        remaining = totalSupply() - totalBurned;
        burnedPercent = (totalBurned * 10_000) / TOTAL_SUPPLY; // in BPS (100 = 1%)
    }
}
