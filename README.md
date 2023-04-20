# ic_no_key_wallet

A stable class exposing wallet funtionalities for EVM based chains.

### Features
- [x] Creating Address
- [ ] Sign Transaction
- [x] Retrieve History
- [x] Clear History
- [x] Deploy EVM Transaction
- [ ] Transfer ERC 20
- [ ] E2E Tests
- [ ] MOPS Support

### Local Environment
These are Ubuntu 22.04 instruction but equivalent instruction should also work on other operating systems.

#### Setup

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
