# Frontier Difficulty Oracle Verification

Byte-for-byte bytecode verification for the difficulty resolution oracle at `0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D` — the world's earliest known on-chain prediction-market resolution oracle.

| Field | Value |
|---|---|
| Contract | [`0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D`](https://etherscan.io/address/0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D) |
| Network | Ethereum Mainnet |
| Block | 76,165 |
| Deployed | 2015-08-12 |
| Deployment tx | [`0xc9f378d160ea94f514a1c166c7221930f6492e7f53055e1c19e51a631cda2bca`](https://etherscan.io/tx/0xc9f378d160ea94f514a1c166c7221930f6492e7f53055e1c19e51a631cda2bca) |
| Deployer | [`0x77b97786b0fb73e55d9e92d4b182befbf346f979`](https://etherscan.io/address/0x77b97786b0fb73e55d9e92d4b182befbf346f979) |
| Compiler | `solc 0.1.0` (native C++ build), optimizer OFF |
| Runtime match | EXACT (477 bytes) |
| Creation match | EXACT (496 bytes) |

## What this contract is

A bet-resolution oracle for a prediction-market system that wagers on Ethereum mining difficulty. A `setWinningOutcome(targetBlock, lower, upper)` call at or after `targetBlock` reads `block.difficulty` and writes a `uint16` outcome:

- `1` if difficulty came in below `lower`
- `10001` if difficulty came in above `upper`
- linear interpolation `0..10000` within range: `10000 * (difficulty - lower) / (upper - lower)`

The packed event key is `targetBlock + lower * (100 * 10**18) + upper * (10000000000000000000000 * 10**18)`, which lets a single `mapping(uint => uint16)` slot index every (block, lower, upper) triple without collisions in any reasonable parameter range.

This contract was deployed on August 12, 2015 — seven days after Ethereum Frontier mainnet launched on July 30, 2015. It is, as far as we know, the earliest deployed contract on Ethereum mainnet that performs on-chain bet resolution off a real-world (here, protocol-level) data source. It predates Augur, Gnosis, and Polymarket by years.

The deployer at `0x77b97786b0fb73e55d9e92d4b182befbf346f979` deployed two related contracts in the same week:

- The fixed-point math library at [`0x258c09146b7a28Dde8d3e230030e27643F91115F`](https://etherscan.io/address/0x258c09146b7a28Dde8d3e230030e27643F91115F) (`e_exp`, `ln`, `floor_log2`, plus admin functions).
- An LMSR market-maker contract at [`0xdb7c577b93baeb56dab50af4d6f86f99a06b96a2`](https://etherscan.io/address/0xdb7c577b93baeb56dab50af4d6f86f99a06b96a2) (creation transaction ran out of gas; no code was deployed at that address).

## How the source was recovered

The on-chain runtime is 477 bytes / 307 opcodes. solc 0.1.0 produces no metadata trailer, no debug info, and no constructor arguments — only the raw constructor + runtime. Recovery proceeded by:

1. **Compiler fingerprinting.** The dispatch table layout and the 24-byte `PUSH` for `10000000000000000000000 * 10**18` pinned the compiler to `solc 0.1.0` (vs `0.1.1`, which produces a different prologue and orders functions oppositely). The native C++ build, not the emscripten port, was confirmed from a 4-line probe that matches the constructor prelude byte-for-byte except for the runtime-length push.
2. **Selector recovery.** `0xbf95d44f` brute-forced to `setWinningOutcome(uint256,uint256,uint256)`, symmetric with the existing `getWinningOutcome(uint256)` getter.
3. **Iterative source matching.** Four probes converged on the canonical `Oracle.sol` here. The two non-obvious quirks of solc 0.1.0:
   - **Operand order matters.** Writing `lower * (100 * 10**18)` compiles correctly; writing `(100 * 10**18) * lower` produces different bytecode.
   - **Don't expand factored expressions.** The in-range outcome is compiled as `10000 * (difficulty - lower) / (upper - lower)`, not the algebraically-equivalent `(10000*difficulty - 10000*lower) / (upper - lower)`.

## Verification

```bash
./verify.sh
```

Requires Docker plus a locally-built `solc 0.1.0` image (see [`BUILD-COMPILER.md`](BUILD-COMPILER.md) — there is no public soljson for `0.1.0`). The script compiles `Oracle.sol`, then diffs the result against both `onchain-runtime.hex` and `onchain-creation.hex`.

## Files

- `Oracle.sol` — the canonical source.
- `onchain-runtime.hex` — `eth_getCode` result for the contract address.
- `onchain-creation.hex` — `eth_getTransactionByHash` input for the deployment transaction.
- `verify.sh` — reproducible compile + diff.
- `BUILD-COMPILER.md` — recipe for the `solc 0.1.0` Docker image.

## Attribution

Reconstruction by [EthereumHistory](https://ethereumhistory.com).
