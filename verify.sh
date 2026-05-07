#!/bin/bash
# verify.sh — compile Oracle.sol with solc 0.1.0 and compare to on-chain bytecode
# Contract: 0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D
# Compiler: solc 0.1.0 (frontier-jul29 native C++ build), optimizer OFF
#
# Requires a local Docker image for the solc 0.1.0 native C++ build.
# There is no public soljson for 0.1.0 — see BUILD-COMPILER.md for how to
# rebuild it from webthree-umbrella sources.

set -e

cd "$(dirname "$0")"

IMAGE="${SOLC_FRONTIER_IMAGE:-solc-frontier-jul29}"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    cat <<EOF
ERROR: Docker image '$IMAGE' not found locally.

solc 0.1.0 has no public soljson distribution; it must be built from source.
See BUILD-COMPILER.md for the recipe (webthree-umbrella, ~10 minutes).

Once built and tagged 'solc-frontier-jul29', re-run this script.
EOF
    exit 2
fi

echo "Compiling Oracle.sol with $IMAGE (solc 0.1.0, optimizer OFF) ..."
RAW=$(docker run --rm -v "$PWD:/src" --entrypoint /umbrella/build/solc/solc "$IMAGE" --binary stdout /src/Oracle.sol 2>/dev/null)
COMPILED_CREATION=$(echo "$RAW" | awk '/^Binary:/{getline; print}' | tr -d '[:space:]')

if [ -z "$COMPILED_CREATION" ]; then
    echo "ERROR: compiler produced no output"
    echo "$RAW"
    exit 1
fi

# Constructor prelude is 38 hex chars; runtime starts after that.
COMPILED_RUNTIME="${COMPILED_CREATION:38}"

ONCHAIN_CREATION=$(tr -d '[:space:]' < onchain-creation.hex)
ONCHAIN_RUNTIME=$(tr -d '[:space:]' < onchain-runtime.hex)

CREATION_BYTES=$((${#ONCHAIN_CREATION} / 2))
RUNTIME_BYTES=$((${#ONCHAIN_RUNTIME} / 2))

ok=1

if [ "$COMPILED_CREATION" = "$ONCHAIN_CREATION" ]; then
    echo "Creation bytecode: EXACT MATCH ($CREATION_BYTES bytes)"
else
    echo "Creation bytecode: MISMATCH"
    ok=0
fi

if [ "$COMPILED_RUNTIME" = "$ONCHAIN_RUNTIME" ]; then
    echo "Runtime bytecode:  EXACT MATCH ($RUNTIME_BYTES bytes)"
else
    echo "Runtime bytecode:  MISMATCH"
    ok=0
fi

if [ $ok -eq 1 ]; then
    echo
    echo "Verified: 0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D"
    exit 0
else
    exit 1
fi
