!/bin/bash

echo "Stopping the existing dfx local replica"
dfx stop

echo "Starting local dfx environment"
dfx start --background --clean

sleep 5

echo "Deploying evm_util canister"
dfx deploy evm_util
EVM_UTIL_ID=$(dfx canister id evm_util)

if [ -z "$EVM_UTIL_ID" ]
then
    echo "Could not deploy the evm_util canister. Exiting ..."
    exit 1
else
    echo "evm_util deployed with id = $EVM_UTIL_ID"
fi

# Replace the evm-util id in the actor reference.
sed -i "s/ubgoy-tiaaa-aaaah-qc7qq-cai/$EVM_UTIL_ID/" src/NoKeyWallet.mo

dfx deploy no_key_wallet

echo "The canisters have been deployed!"
