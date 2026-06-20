// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// JDP — JD Productions Token (V2)
// A decentralized utility currency for the JDP ecosystem (JDP Pay).
// Architecture: free-transacting currency, launch-protected, burn-to-use scarcity.
// Control model: you control the ECOSYSTEM (treasury, burn policy, launch).
//                the COIN decentralizes (limits lift, trades freely like a real currency).

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JDPToken is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000 * 1e18; // 100M fixed — Bitcoin scarcity + BNB burn-success + reachable $1

    // ── Burn-to-use (BNB-style scarcity) ──────────────────────────────────────
    uint256 public burnRateBps = 50;             // 0.5% of each transfer burned
    uint256 public constant MAX_BURN_BPS = 200;  // hard ceiling 2% — you can NEVER exceed this

    // ── Launch protection (training wheels — removable) ───────────────────────
    bool public tradingActive = false;  // anti-snipe: trading opens only when YOU say go
    bool public limitsActive  = true;   // anti-bot caps on at launch, off when stable
    uint256 public maxTxAmount;         // max tokens per transaction
    uint256 public maxWalletAmount;     // max tokens a wallet can hold

    // Exempt from limits + burn (liquidity pool ops, treasury, JDP Pay contracts)
    mapping(address => bool) public isExempt;

    event TradingEnabled();
    event LimitsRemoved();
    event LimitsUpdated(uint256 maxTx, uint256 maxWallet);
    event BurnRateUpdated(uint256 bps);

    constructor(address treasury) ERC20("JD Productions Token", "JDP") Ownable(msg.sender) {
        _mint(treasury, MAX_SUPPLY);

        // Launch caps: 0.5% max per tx, 1% max per wallet (adjustable by you)
        maxTxAmount     = (MAX_SUPPLY * 50)  / 10000; // 0.5%
        maxWalletAmount = (MAX_SUPPLY * 100) / 10000; // 1%

        isExempt[msg.sender] = true;
        isExempt[treasury]   = true;
    }

    // ── Your enterprise controls ──────────────────────────────────────────────

    /// Open the market. Call this at the exact launch moment (anti-snipe).
    function enableTrading() external onlyOwner {
        tradingActive = true;
        emit TradingEnabled();
    }

    /// Free the currency. Lifts all caps so JDP can function as real money.
    function removeLimits() external onlyOwner {
        limitsActive = false;
        emit LimitsRemoved();
    }

    /// Tune the launch caps before lifting them entirely.
    function setLimits(uint256 _maxTx, uint256 _maxWallet) external onlyOwner {
        maxTxAmount = _maxTx;
        maxWalletAmount = _maxWallet;
        emit LimitsUpdated(_maxTx, _maxWallet);
    }

    /// Adjust burn rate (capped at 2% — trust guardrail you cannot override).
    function setBurnRate(uint256 _bps) external onlyOwner {
        require(_bps <= MAX_BURN_BPS, "burn exceeds 2% ceiling");
        burnRateBps = _bps;
        emit BurnRateUpdated(_bps);
    }

    /// Exempt infrastructure (pool, treasury, JDP Pay) from limits + burn.
    function setExempt(address account, bool exempt) external onlyOwner {
        isExempt[account] = exempt;
    }

    // ── Transfer logic: trading gate + anti-bot caps + burn-to-use ────────────

    function _update(address from, address to, uint256 value) internal override {
        // Mints (from == 0) and burns (to == 0) always pass.
        if (from != address(0) && to != address(0)) {
            bool exempt = isExempt[from] || isExempt[to];

            // Anti-snipe: no trading until you open it (exempt parties can seed liquidity).
            if (!tradingActive) {
                require(exempt, "trading not active");
            }

            if (!exempt) {
                // Anti-bot launch caps
                if (limitsActive) {
                    require(value <= maxTxAmount, "exceeds max tx");
                    require(balanceOf(to) + value <= maxWalletAmount, "exceeds max wallet");
                }
                // Burn-to-use: true supply reduction (scarcity grows with usage)
                if (burnRateBps > 0) {
                    uint256 burnAmount = (value * burnRateBps) / 10000;
                    if (burnAmount > 0) {
                        super._update(from, address(0), burnAmount); // to address(0) = real burn
                        value -= burnAmount;
                    }
                }
            }
        }
        super._update(from, to, value);
    }
}
