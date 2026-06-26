# DeFi Protocol Governance / Admin Risk Report Template

Use this template when reporting the results of a reviews/defi-protocol.md review.

---

```
╔══════════════════════════════════════════════════════════════════╗
  DEFI PROTOCOL SECURITY ASSESSMENT — [Protocol Name]
  stride_categories: [...]
╠══════════════════════════════════════════════════════════════════╣
  Address:    [Multiple privileged contracts (see SURFACE) | or single proxy if compact]
  Chain:      [Ethereum / BSC / Solana / etc.]
  Type:       [Lending / Yield / RWA / Stableswap / etc.]
  Label:      [Reputation note, audit pedigree]
  Source:     [Citation: DeFiScan thread, SlowMist report, on-chain query, etc.]
╠══════════════════════════════════════════════════════════════════╣
  STRIDE CLASSIFICATION (Step 0)
  S (Spoofing)        [none/suspect/confirmed]    [evidence]
  T (Tampering)       [none/suspect/confirmed]    [evidence]
  R (Repudiation)     [none/suspect/confirmed]    [evidence]
  I (Info Disclosure) [none/suspect/confirmed]    [evidence]
  D (DoS)             [none/suspect/confirmed]    [evidence]
  E (EoP)             [none/suspect/confirmed]    [evidence]
  --
  [N] confirmed → risk floor [🟢/🟡/🔴]
╠══════════════════════════════════════════════════════════════════╣
  PRIVILEGED SURFACE ([n] nodes)
  Top-level         [contract / governance entity]
  Emergency layer   [multisig list with m-of-n and signer publicity]
  Upgradeable       [proxy contracts and their admin]
  Config / registry [setter contracts, address provider, oracle, ACL]
╠══════════════════════════════════════════════════════════════════╣
  CONTRACT ANALYSIS
  Verified:        [Yes / No across the privileged surface]
  Proxy:           [Yes / No, who controls upgrade]
  Owner Perms:     [list of privileged functions across surface]
  Approval Risk:   [unlimited paths / capped / none]
  Known Vulns:     [list or "None identified"]
╠══════════════════════════════════════════════════════════════════╣
  TIMELOCK PROFILE
  [action]                          [delay]   [path]
  ...
  --
  [Calibration note: who is 18h enough for? how many 0-delay actions exist?]
╠══════════════════════════════════════════════════════════════════╣
  SYSTEM DEPENDENCIES
  [1-2 sentences naming upstream chokepoints and cascade paths]
╠══════════════════════════════════════════════════════════════════╣
  RISK:     [🟢 LOW / 🟡 MEDIUM / 🔴 HIGH / ⛔ REJECT]
  VERDICT:  [✅ SAFE TO INTERACT / ⚠️ CAUTION / ❌ DO NOT INTERACT]
╠══════════════════════════════════════════════════════════════════╣
  USAGE GUARDRAILS (if proceeding)
  1. [position sizing rule]
  2. [monitoring obligation: timelock queue, multisig tx, upgrade events]
  3. [holding period / accumulation limit]
  4. [exit trigger]
  ...
╠══════════════════════════════════════════════════════════════════╣
  OWN-PROTOCOL CROSS-CHECK (optional, omit for pre-deposit DD)
  Q1  [equivalent emergency freeze? multisig / signers / delay?]
  Q2  [reward / treasury upgradeability + timelock?]
  Q3  [ALM-style liquidity layer with controller approval cap?]
  Q4  [multisig signer publicity?]
  Q5  [timelock baseline vs target user distribution?]
  Q6  [component swap surface: registry / oracle / ACL?]
╠══════════════════════════════════════════════════════════════════╣
  NOTES
  [Methodology caveats, what wasn't checked, related findings]
╚══════════════════════════════════════════════════════════════════╝
```

## Field Guidelines

- **Address**: For protocol-level review, list "Multiple privileged contracts" and enumerate in PRIVILEGED SURFACE section. Don't try to fit a 12-node surface into a single Address line.
- **STRIDE evidence**: Cite the specific finding (contract name, function, observed behavior). "confirmed" claims must be backed by the report body.
- **Timelock 0-delay rows**: Always list separately or annotate. The headline insight of any DeFi admin audit is "what can the team do without warning".
- **Approval Risk**: Specifically check for unlimited approval paths. Any "controller can drain X" path goes here (Spark ALMProxy precedent).
- **Verdict vs Risk**: 🔴 HIGH + ⚠️ CAUTION is the common pairing. Don't auto-escalate verdict to ❌ when the protocol is legitimate but admin keys are concentrated.
- **Cross-check section**: Omit entirely when user is doing pre-deposit due diligence on a protocol they don't operate. Include only when user is building or operating a peer protocol.
