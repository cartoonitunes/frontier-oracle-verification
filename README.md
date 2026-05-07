# Frontier Difficulty Oracle Verification

Byte-for-byte bytecode verification for the **world's earliest known on-chain prediction-market oracle**.

| Field | Value |
|---|---|
| Contract | [`0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D`](https://etherscan.io/address/0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D) |
| Network | Ethereum Mainnet |
| Block | 76,165 |
| Deployed | 2015-08-12 (~7 days post-Frontier launch) |
| Deployment tx | [`0xc9f378d1…cda2bca`](https://etherscan.io/tx/0xc9f378d160ea94f514a1c166c7221930f6492e7f53055e1c19e51a631cda2bca) |
| Deployer | [`0x77b97786b0fb73e55d9e92d4b182befbf346f979`](https://etherscan.io/address/0x77b97786b0fb73e55d9e92d4b182befbf346f979) (Stefan George) |
| Compiler | `solc 0.1.0` (`frontier-jul29` native C++ build) |
| Optimizer | OFF |
| Runtime match | EXACT (477 bytes) |
| Creation match | EXACT (496 bytes) |

## What this contract is

The third leg of Stefan George's pre-Gnosis prediction-market stack, deployed in a single week in August 2015:

- `0x258c…115F` — fixed-point math library (e_exp / ln / log2)
- **`0x33cA…B10D` — resolution oracle (this contract)**
- `0xdb7c…b96a2` — LMSR market maker ("Behemoth")

The oracle resolves bets on Ethereum mining difficulty. A `setWinningOutcome(targetBlock, lower, upper)` call at or after `targetBlock` reads `block.difficulty` and writes a `uint16` outcome:

- `1` if difficulty came in below `lower`
- `10001` if difficulty came in above `upper`
- linear interpolation `0..10000` within range: `10000 * (difficulty - lower) / (upper - lower)`

The packed event key is `targetBlock + lower * (100 * 10**18) + upper * (10000000000000000000000 * 10**18)`, which lets a single `mapping(uint => uint16)` slot index every (block, lower, upper) triple without collisions in any reasonable parameter range.

This is, as far as we know, the earliest deployed contract on Ethereum mainnet that performs **on-chain bet resolution** off a real-world (here, protocol-level) data source. It predates Augur, Gnosis, and Polymarket by years.

## How the source was recovered

The on-chain runtime is 477 bytes / 307 opcodes. solc 0.1.0 produces no metadata trailer, no debug info, and no constructor arguments — only the raw constructor + runtime. Recovery proceeded by:

1. **Compiler fingerprinting.** The dispatch table layout and the `701d…` 24-byte PUSH for `10000000000000000000000 * 10**18` pinned the compiler to `solc 0.1.0` (vs 0.1.1, which produces a different prologue and orders functions oppositely). The native C++ `frontier-jul29` build, not the emscripten port, was confirmed from a 4-line probe that matches the constructor prelude byte-for-byte except for the runtime-length push.
2. **Selector recovery.** `0xbf95d44f` brute-forced to `setWinningOutcome(uint256,uint256,uint256)`. The other selector `0x084d72f4` is the existing `getWinningOutcome(uint256)` getter.
3. **Iterative source matching.** Four probes converged on the canonical `Oracle.sol` here. The two non-obvious quirks of solc 0.1.0:
   - **Operand order matters.** Writing `lower * (100 * 10**18)` compiles correctly; writing `(100 * 10**18) * lower` produces different bytecode.
   - **Don't expand factored expressions.** The in-range outcome is compiled as `10000 * (difficulty - lower) / (upper - lower)`, not the algebraically-equivalent `(10000*difficulty - 10000*lower) / (upper - lower)`.

## Verification

```bash
./verify.sh
```

Requires Docker. Pulls the `solc 0.1.0` native build from the public mirror, compiles `Oracle.sol`, and diffs against both `onchain-runtime.hex` and `onchain-creation.hex`.

## Files

- `Oracle.sol` — the canonical source (35 lines, 2 functions plus fallback)
- `onchain-runtime.hex` — `eth_getCode` result for `0x33cA…B10D`
- `onchain-creation.hex` — `eth_getTransactionByHash` input for the deployment tx
- `verify.sh` — reproducible compile + diff

## Attribution

Reconstruction by EthereumHistory ([ethereumhistory.com](https://ethereumhistory.com)).
