#!/bin/bash

rm -rf third_party
mkdir -p third_party && cd third_party

echo "Cloning evm_utils"
git clone git@github.com:icopen/evm_utils_ic.git ./evm_utils

echo "Building evm_utils"
cd evm_utils
mkdir -p gen
CARGO_TARGET_DIR=gen cargo build --target wasm32-unknown-unknown --release
ic-wasm gen/wasm32-unknown-unknown/release/evm_utils.wasm -o gen/wasm32-unknown-unknown/release/evm_utils_opt.wasm shrink
