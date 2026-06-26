# DeFi Protocol Governance / Admin Risk Review

## Trigger

- A DeFiScan, SlowMist, or Token Terminal thread / report on protocol admin risk
- User asks "is X protocol safe to deposit into" or "看 X 協議的中央化風險"
- Pre-deposit due diligence on a lending / yield / RWA / stableswap protocol
- Peer-protocol audit while building or operating your own protocol
- Any framing where the question is "trust assumptions of this protocol", not "is this address malicious"

**Use reviews/onchain.md instead when:**
- The target is a single address, single transaction, or single signature
- The question is AML / sanction / phishing label
- Interaction is one-shot, not ongoing custody

## Review Flow

Step 0 (STRIDE classification per SKILL.md) is mandatory and runs first.

### Step 1: Privileged Surface Enumeration

List every node holding admin / upgrade / freeze / config / registry power.

Group by tier:

| Tier | Examples |
|---|---|
| Top-level governance | DAO contract, governance token, timelock |
| Emergency multisigs | smaller m-of-n with bypass / freeze powers |
| Upgradeable proxy admins | who can swap implementation? |
| Config setters | rate setter, threshold setter, oracle setter, reward setter |
| Registry / address provider | who can swap component contracts? |

Output table:

| Layer | Contract / Multisig | Type | What it can do |
|---|---|---|---|
| ... | ... | ... | ... |

Common red flags at this step:
- Multisig signers not publicly announced
- Same powers held at multiple tiers (governance + emergency multisig)
- EOA admin (not multisig, not contract)
- More than 8 privileged nodes (surface area inflation)

### Step 2: Timelock Profile

Per-action delay matrix. Headline question: between malicious action and execution, how much time do users have to react?

| Action | Delay | Path |
|---|---|---|
| Governance proposal execution | ... | DAO vote → timelock |
| Emergency freeze | ... | multisig direct |
| Proxy upgrade | ... | ... |
| Reward parameter change | ... | ... |
| Config / threshold change | ... | ... |
| Registry / oracle swap | ... | ... |

**0-delay actions are listed separately and counted.** 0 delay equals absolute trust in key holders for that action.

Calibration:
- 0-delay critical action (freeze / upgrade / drain path) → 🔴 HIGH floor
- Sub-6h delay on any action affecting user funds → 🟡 MEDIUM floor
- 18h+ on all material actions → baseline acceptable, still note user-distribution fit (passive LPs, cross-timezone holders may need more)

### Step 3: Approval / Allowance Surface

- Does any privileged contract grant unlimited approval to another contract?
- Are approval paths capped or uncapped?
- Single-controller-drain risk: one compromised controller equals full TVL drain?

If yes to any, list explicitly. This is the path that turned Spark Protocol's ALMProxy into a confirmed E (EoP) signal in the 2026-05-04 DeFiScan thread.

### Step 4: System Dependency Map

- What underlying assets does the protocol depend on (stablecoins, LSTs, RWA wrappers)?
- Who controls those upstream assets (governance, multisig, off-chain entity)?
- Cascade failure path: if upstream is upgraded maliciously, what fails downstream?

Output: 1-2 sentences naming the upstream chokepoints. Spark example: entire protocol routes through USDS / sUSDS, both upgradeable by Sky governance, so Sky-side compromise cascades to Spark.

### Step 5: Usage Guardrails

If user proceeds despite the rating, what are the operational guardrails?

- Position sizing relative to trust assumption count (more privileged nodes = smaller position)
- Monitoring obligations (timelock queue, multisig tx feed, upgrade events)
- Holding-period limits (e.g. don't accumulate unclaimed rewards if reward setter is 0-delay)
- Exit triggers (specific on-chain events that should prompt withdrawal)

These are not optional fluff. The rating tells the user "go / caution / no". Guardrails tell them how to live with caution.

### Step 6: Cross-check Against Own Protocol (optional)

When the user is building or operating a peer protocol, surface gap questions for their own surface.

Template (prune / extend per protocol):

- Q1: Equivalent emergency freeze? Multisig size, public signers, delay?
- Q2: Reward / Treasury upgradeability? Path? Timelock?
- Q3: ALM-style liquidity layer? Controller approval cap?
- Q4: Multisig signer publicity?
- Q5: Timelock baseline vs target user distribution?
- Q6: Component swap surface (registry / oracle / ACL)?

Skip this step entirely when user is doing pre-deposit due diligence on a protocol they don't operate.

### Step 7: Rating and Report

**MUST** use [templates/report-defi-protocol.md](../templates/report-defi-protocol.md).

## Risk Floor

- 2+ confirmed STRIDE categories → 🔴 HIGH (already enforced by Step 0)
- Single-controller-drain path detected → 🔴 HIGH
- Anonymous multisig with bypass power → 🔴 HIGH
- Unverified contracts in privileged path → 🔴 HIGH
- 1 confirmed 0-delay privileged action → 🟡 MEDIUM minimum
- All actions ≥ 18h timelock + multisig signers public + no unlimited approvals → 🟢 LOW achievable

## Verdict Calibration

| Verdict | When |
|---|---|
| ✅ SAFE TO INTERACT | Rare. Reserve for fully immutable, no-admin contracts (e.g. Liquity v1 style) |
| ⚠️ CAUTION | Most legitimate DeFi protocols land here. User proceeds with eyes open + guardrails |
| ❌ DO NOT INTERACT | Active exploit, confirmed honeypot, admin keys held by sanctioned / blacklisted entity, or unverified privileged contract |

A 🔴 HIGH risk rating with ⚠️ CAUTION verdict is the common pairing for legitimate but admin-key-concentrated protocols. Don't conflate "high risk" with "do not interact".

## Origin

Extracted from the 2026-05-05 Spark Protocol assessment session. The 9-risk DeFiScan thread (https://x.com/defiscan_info/status/2051336706922590424) exposed three gaps in reviews/onchain.md when applied to a multi-contract protocol: timelock-per-action profiling, usage guardrails for proceed-with-caution cases, and cross-check against own protocol. This review type fills those gaps without forcing onchain.md to stretch beyond single-address scope.
