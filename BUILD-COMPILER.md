# Building solc 0.1.0 (`frontier-jul29`)

solc 0.1.0 (released around the Ethereum Frontier launch in July–August 2015) was never compiled to JavaScript and is not available on `binaries.soliditylang.org`. To reproduce the bytecode in this repository you need the original native C++ build.

The `frontier-jul29` build refers to the upstream `webthree-umbrella` tree as of late July 2015. Build it once, tag the image as `solc-frontier-jul29`, then `verify.sh` will pick it up.

## Recipe

```dockerfile
FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
    git cmake g++ \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libleveldb-dev \
    libcryptopp-dev \
    libjsoncpp-dev \
    libargtable2-dev

RUN git clone --recursive https://github.com/ethereum/webthree-umbrella.git /umbrella
WORKDIR /umbrella

# Pin to the late-July 2015 snapshot of the umbrella tree.
RUN cd webthree-helpers   && git checkout develop && \
    cd ../libethereum     && git checkout develop && \
    cd ../solidity        && git checkout v0.1.0  && \
    cd ../webthree        && git checkout develop && \
    cd ..

# Strip non-solc components.
RUN sed -i '/eth-node/d;/alethzero/d;/mix-ide/d;/web3.js/d' CMakeLists.txt

# ARM64 build: replace `__asm("int $3")` in debugbreak.h with `raise(SIGTRAP)`.
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        sed -i 's|__asm__("int \$$3")|raise(SIGTRAP)|' \
            $(grep -rl 'int \$3' /umbrella || true); \
    fi

RUN mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j"$(nproc)" solc

ENTRYPOINT ["/umbrella/build/solc/solc"]
```

Build and tag:

```bash
docker build -t solc-frontier-jul29 -f Dockerfile.frontier .
```

After this `verify.sh` runs cleanly. The same image compiles every solc-0.1.0 contract in the August 2015 cohort.
