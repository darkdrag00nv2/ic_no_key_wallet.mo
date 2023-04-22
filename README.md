# ic_no_key_wallet

A stable class exposing wallet funtionalities for EVM based chains.

### Features
- [x] Creating Address
- [ ] Sign Transaction
- [x] Retrieve History
- [x] Clear History
- [x] Deploy EVM Transaction
- [x] Transfer ERC 20
- [ ] E2E Tests
- [ ] MOPS Support

### Local Environment
These are Ubuntu 22.04 instruction but equivalent instruction should also work on other operating systems.

#### Setup

This library relies on the EVM utility canister. For local development, the provided scripts clone the canister source code and build it. To build the utility canister, you'll need to install the following tools and libraries.

Install Rust using [`rustup`](https://rustup.rs/).

You might have to install `curl`, `gcc`, `make` and `build-essentials` to be able to use `rustup`.

```bash
sudo apt install -y curl gcc make build-essential
```

Apart from the standard Rust installation, you also need to install wasm support.

```bash
rustup target add wasm32-unknown-unknown
```

Install `ic-wasm` to optimize the wasm files.
```
cargo install ic-wasm
```

You'll also need Clang.

```bash
sudo apt update
sudo apt -y install clang
```

#### Start
Once the setup is done, you can just use the provided `local.sh` script to deploy the canisters.

```bash
./local.sh
```

This script will also pull the `evm-utility` canister, build and deploy it. So, it might take a few minutes on the first run.
