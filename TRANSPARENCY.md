# JDP Coin — Wallet & Supply Transparency

**Token:** JD Productions Token (JDP) · ERC-20 on **Base** (Chain ID 8453)
**Contract:** `0x1d442F1CfCe1C08193d529aC07Db72E02C30DfB3`
**Total Supply:** 100,000,000 JDP (fixed, no mint)

Every allocation is held in a public, verifiable address — multisig vaults, a vesting contract, or the liquidity pool. No single hot wallet holds the supply.

## Allocation & wallets

| Allocation | % | Amount | Address | Security |
|---|---|---|---|---|
| Community | 35% | 35,000,000 | `0xFE298f826b074cd686f60a117fE2eD440c0CE682` | Gnosis Safe, 3-of-4 multisig |
| Reserve | 25% | 25,000,000 | `0x2dAED3525E4cF9eaA15BB6F9e46f5d49fa302B19` | Gnosis Safe, 3-of-4 multisig (cold) |
| Treasury + Marketing + LP reserve | 25% | 24,930,000 | `0xc2a582f46475c504432f11988a10b8fCf7E8890d` | Gnosis Safe, 3-of-4 multisig |
| Founder | 15% | 15,000,000 | `0xBD0d62cCFb9D18Aa57d84b1a4ef093937fBb4856` | Vesting contract — 3-year linear, 12-month cliff |
| Liquidity (live) | — | 70,000 | `0xebfeeb3a198fefd42181a70af2becdb4affb04ef` | Aerodrome JDP/WETH pool |

**Owner key** (contract control only — holds no supply): `0xAdff285BfbCDcF579788d6904C7b767b6e394549`

## Notes
- Founder allocation is **locked in a vesting contract** — cannot be dumped; releases linearly over 3 years after a 12-month cliff.
- Treasury/Reserve/Community are **3-of-4 multisig Safes** — no single device can move funds.
- JDP is a **participation asset** of the JD ecosystem — used to access tools, services, memberships, and opportunities. Not a security, not investment advice.

## BaseScan public name tags (requested)
| Address | Name tag |
|---|---|
| `0xFE298f…E682` | JDP: Community (Multisig) |
| `0x2dAED3…2B19` | JDP: Reserve (Multisig) |
| `0xc2a582…890d` | JDP: Treasury (Multisig) |
| `0xBD0d62…4856` | JDP: Founder Vesting |
| `0xebfeeb…04ef` | JDP: Aerodrome LP |

---

## Security Notes (context for automated scanners)

Automated scanners (e.g. GoPlus) flag a few items on the JDP contract. Here is the honest context — all are standard launch-protection, not honeypot risks, and all are verifiable in the public source:

- **"Anti-whale / transaction limited"** — JDP launches with per-transaction and per-wallet **anti-bot caps** so no single bot can drain the thin launch liquidity. These are **temporary** and removed via `removeLimits()` once the market stabilizes, after which JDP transacts freely.
- **"Anti-whale is modifiable"** — this simply refers to `setLimits()` / `removeLimits()`, the functions used to *lift* the caps above.
- **"Tax can be modified"** — the 0.5% burn rate is adjustable via `setBurnRate()`, **but it is hard-capped at 2% in the contract (`MAX_BURN_BPS = 200`)**. It is mathematically impossible to raise it to a honeypot level. Verify in the source.

**What the contract does NOT have** (the actually dangerous features): no mint function (supply is fixed at 100M), no blacklist, no hidden owner, no ability to block selling, no proxy/upgradeability. Source verified on BaseScan, Sourcify, and Blockscout.

Owner powers are bounded and will move to the Treasury multisig as the project matures.
