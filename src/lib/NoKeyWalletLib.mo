/// Stable class adding wallet support for EVM based chains.
///
/// TODO: Add more details
import EvmUtil "EvmUtil";
import Types "Types";
import Principal "mo:base/Principal";
import IcManagement "IcManagement";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import State "State";
import Nat64 "mo:base/Nat64";
import Buffer "mo:base/Buffer";
import Nat8 "mo:base/Nat8";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import { now } = "mo:base/Time";
import Map "mo:stable_hash_map/Map/Map";
import StableBuffer "mo:stable_buffer/StableBuffer";
import Binary "mo:encoding/Binary";

module {
    type EvmUtil = EvmUtil.EvmUtil;
    type IcManagement = IcManagement.IcManagement;

    type CreateAddressResponse = Types.CreateAddressResponse;
    type SignTransactionResponse = Types.SignTransactionResponse;
    type DeployContractResponse = Types.DeployContractResponse;
    type UserResponse = Types.UserResponse;
    type Result<X> = Types.Result<X>;

    type State = State.State;
    type UserData = State.UserData;
    type TransactionData = State.TransactionData;
    type Env = State.Env;

    type Transaction = EvmUtil.Transaction;
    type Signature = EvmUtil.Signature;

    type Map<K, V> = Map.Map<K, V>;
    let { n64hash } = Map;

    public type NoKeyWalletLib = {
        evmUtil : EvmUtil;
        icManagement : IcManagement;
        state : State;
    };

    public func init(
        initEvmUtil : EvmUtil,
        initIcManagement : IcManagement,
        env : Env,
    ) : NoKeyWalletLib = {
        evmUtil = initEvmUtil;
        icManagement = initIcManagement;
        state = State.initState(env);
    };

    /// Create an address for the provided principal.
    ///
    /// The address is saved in the user state and can be used later to sign a transaction.
    public func createAddress(
        lib : NoKeyWalletLib,
        caller_principal : Principal,
    ) : async Result<CreateAddressResponse> {
        try {
            let { public_key } = await lib.icManagement.ecdsa_public_key({
                canister_id = null;
                derivation_path = [Principal.toBlob(caller_principal)];
                key_id = {
                    curve = #secp256k1;
                    name = lib.state.config.key_name;
                };
            });

            let address_or_error = await lib.evmUtil.pub_to_address(Blob.toArray(public_key));
            switch (address_or_error) {
                case (#Ok(address)) {
                    State.addUserPublicKey(lib.state, caller_principal, public_key);
                    return #Ok({ address });
                };
                case (#Err(msg)) { return #Err(msg) };
            };
        } catch (err) {
            #Err(Error.message(err));
        };
    };

    /// Sign the provided raw transaction.
    ///
    /// The transaction will be signed for the provided chain_id.
    /// It will saved in the transaction history for the user if save_history is true.
    public func signTransaction(
        lib : NoKeyWalletLib,
        raw_txn : [Nat8],
        chain_id : Nat64,
        caller_principal : Principal,
        save_history : Bool,
    ) : async Result<SignTransactionResponse> {
        switch (State.getUserData(lib.state, caller_principal)) {
            case (null) {
                return #Err("The user does not exist");
            };
            case (?userData) {
                let txn = await lib.evmUtil.parse_transaction(raw_txn);

                switch (txn) {
                    case (#Err(msg)) { return #Err(msg) };
                    case (#Ok(txn)) {
                        let message_hash = await lib.evmUtil.keccak256(raw_txn);
                        if (message_hash.size() != 32) {
                            return #Err("unexpected length of message hash. Aborting!");
                        };

                        try {
                            Cycles.add(lib.state.config.sign_cycles);
                            let { signature } = await lib.icManagement.sign_with_ecdsa({
                                message_hash = Blob.fromArray(message_hash);
                                derivation_path = [Principal.toBlob(caller_principal)];
                                key_id = {
                                    curve = #secp256k1;
                                    name = lib.state.config.key_name;
                                };
                            });

                            let signed_txn_serialized = await signTransactionWithSignature(
                                lib,
                                txn,
                                chain_id,
                                message_hash,
                                signature,
                                userData.public_key,
                            );
                            switch (signed_txn_serialized) {
                                case (#Err(msg)) {
                                    return #Err(msg);
                                };
                                case (#Ok(signed_txn_serialized)) {
                                    let txn_data : TransactionData = {
                                        data = signed_txn_serialized;
                                        timestamp = now();
                                    };

                                    State.addTransactionForUser(
                                        lib.state,
                                        caller_principal,
                                        txn_data,
                                        chain_id,
                                        getNonceFromTransaction(txn),
                                    );

                                    return #Ok({
                                        signed_txn = signed_txn_serialized;
                                    });
                                };
                            };
                        } catch (err) {
                            return #Err(Error.message(err));
                        };
                    };
                };
            };
        };
    };

    private func signTransactionWithSignature(
        lib : NoKeyWalletLib,
        txn : Transaction,
        chain_id : Nat64,
        msg_hash : [Nat8],
        signature : Blob,
        public_key : Blob,
    ) : async Result<[Nat8]> {
        let sig_bytes = Blob.toArray(signature);
        let public_key_bytes = Blob.toArray(public_key);

        // We don't validate msg_hash size since it is already validated by the caller.
        if (sig_bytes.size() != 64) {
            return #Err("Invalid signature returned from sign_with_ecdsa");
        } else if (public_key_bytes.size() != 33) {
            return #Err("Invalid public key when signing transaction");
        };

        let r = Array.subArray(sig_bytes, 0, 4);
        let s = Array.subArray(sig_bytes, 4, 4);
        let recovery_id = await getRecoveryId(lib, msg_hash, sig_bytes, public_key_bytes);

        let v : Nat64 = switch (recovery_id) {
            case (#Err(msg)) {
                return #Err(msg);
            };
            case (#Ok(recovery_id)) {
                switch (txn) {
                    case (#Legacy(txn_legacy)) {
                        chain_id * 2 + 35 + Nat64.fromNat(Nat8.toNat(recovery_id));
                    };
                    case (#EIP1559(txn_1559)) {
                        if (recovery_id == 0) 0 else 1;
                    };
                    case (#EIP2930(txn_2930)) {
                        if (recovery_id == 0) 0 else 1;
                    };
                };
            };
        };

        let signature_info : Signature = {
            r = r;
            s = s;
            v = v;
            hash = msg_hash;
            from = null;
        };
        let signed_txn = cloneTransactionWithSignatureInfo(txn, signature_info);

        // TODO: create_transaction does not support encoding signature information.
        // https://github.com/icopen/evm_utils_ic/issues/3
        let signed_txn_encoded = await lib.evmUtil.create_transaction(signed_txn);
        switch (signed_txn_encoded) {
            case (#Err(msg)) {
                return #Err(msg);
            };
            case (#Ok((signed_txn_encoded, _))) {
                return #Ok(signed_txn_encoded);
            };
        };
    };

    private func getRecoveryId(
        lib : NoKeyWalletLib,
        msg_hash : [Nat8],
        sig_bytes : [Nat8],
        public_key_bytes : [Nat8],
    ) : async Result<Nat8> {

        return #Err("TODO");
    };

    private func cloneTransactionWithSignatureInfo(txn : Transaction, sign : Signature) : Transaction {
        switch (txn) {
            case (#Legacy(txn_legacy)) {
                return #Legacy({
                    chain_id = txn_legacy.chain_id;
                    data = txn_legacy.data;
                    gas_price = txn_legacy.gas_price;
                    gas_limit = txn_legacy.gas_limit;
                    sign = ?sign;
                    to = txn_legacy.to;
                    value = txn_legacy.value;
                    nonce = txn_legacy.nonce;
                });
            };
            case (#EIP1559(txn_1559)) {
                return #EIP1559({
                    access_list = txn_1559.access_list;
                    chain_id = txn_1559.chain_id;
                    data = txn_1559.data;
                    max_fee_per_gas = txn_1559.max_fee_per_gas;
                    max_priority_fee_per_gas = txn_1559.max_priority_fee_per_gas;
                    gas_limit = txn_1559.gas_limit;
                    sign = ?sign;
                    to = txn_1559.to;
                    value = txn_1559.value;
                    nonce = txn_1559.nonce;
                });
            };
            case (#EIP2930(txn_2930)) {
                return #EIP2930({
                    access_list = txn_2930.access_list;
                    chain_id = txn_2930.chain_id;
                    data = txn_2930.data;
                    gas_limit = txn_2930.gas_limit;
                    gas_price = txn_2930.gas_price;
                    sign = ?sign;
                    to = txn_2930.to;
                    value = txn_2930.value;
                    nonce = txn_2930.nonce;
                });
            };
        };
    };

    private func getNonceFromTransaction(txn : Transaction) : [Nat8] {
        switch (txn) {
            case (#Legacy(txn_legacy)) {
                return txn_legacy.nonce;
            };
            case (#EIP1559(txn_1559)) {
                return txn_1559.nonce;
            };
            case (#EIP2930(txn_2930)) {
                return txn_2930.nonce;
            };
        };
    };

    /// Get the transaction history of the principal for the provided chain_id.
    public func getCallerHistory(
        lib : NoKeyWalletLib,
        chain_id : Nat64,
        caller_principal : Principal,
    ) : async Result<UserResponse> {
        switch (State.getUserData(lib.state, caller_principal)) {
            case (null) {
                return #Err("User does not exist");
            };
            case (?userData) {
                let address_or_error = await lib.evmUtil.pub_to_address(Blob.toArray(userData.public_key));
                switch (address_or_error) {
                    case (#Ok(address)) {
                        let txn_chain_data = Map.get(userData.transactions, n64hash, chain_id);
                        let transaction_data : ?Types.TransactionData = switch (txn_chain_data) {
                            case (null) {
                                null;
                            };
                            case (?txn_chain_data) {
                                ?{
                                    last_nonce = txn_chain_data.last_nonce;
                                    transactions = StableBuffer.toArray(txn_chain_data.transactions);
                                };
                            };
                        };

                        return #Ok(
                            {
                                address = address;
                                transactions = transaction_data;
                            }
                        );
                    };
                    case (#Err(msg)) { return #Err(msg) };
                };
            };
        };
    };

    /// Clear the transaction history of the principal for the provided chain_id.
    public func clearCallerHistory(
        lib : NoKeyWalletLib,
        chain_id : Nat64,
        caller_principal : Principal,
    ) : async Result<()> {
        switch (State.getUserData(lib.state, caller_principal)) {
            case (null) {
                return #Err("User does not exist");
            };
            case (?userData) {
                Map.delete(userData.transactions, n64hash, chain_id);
                return #Ok(());
            };
        };
    };

    /// Create a signed EVM contract with the provided parameters.
    public func deployEvmContract(
        lib : NoKeyWalletLib,
        caller_principal : Principal,
        bytecode : [Nat8],
        chain_id : Nat64,
        max_priority_fee_per_gas : Nat64,
        gas_limit : Nat64,
        max_fee_per_gas : Nat64,
    ) : async Result<DeployContractResponse> {
        switch (State.getUserData(lib.state, caller_principal)) {
            case (null) {
                return #Err("User does not exist");
            };
            case (?userData) {
                let txn_chain_data = Map.get(userData.transactions, n64hash, chain_id);
                let nonce : Nat64 = switch (txn_chain_data) {
                    case (null) {
                        0;
                    };
                    case (?txn_chain_data) {
                        nat8ToNat64(txn_chain_data.last_nonce) + 1;
                    };
                };

                let txn : Transaction = #EIP1559({
                    access_list = [];
                    chain_id = chain_id;
                    data = bytecode;
                    max_fee_per_gas = nat64ToNat8(max_fee_per_gas);
                    max_priority_fee_per_gas = nat64ToNat8(max_priority_fee_per_gas);
                    gas_limit = nat64ToNat8(gas_limit);
                    sign = null;
                    to = nat64ToNat8(0);
                    value = nat64ToNat8(0);
                    nonce = nat64ToNat8(nonce);
                });

                let txn_encoded = await lib.evmUtil.create_transaction(txn);
                switch (txn_encoded) {
                    case (#Err(msg)) {
                        return #Err(msg);
                    };
                    case (#Ok(txn_encoded, _)) {
                        let signed_txn = await signTransaction(
                            lib,
                            txn_encoded,
                            chain_id,
                            caller_principal,
                            true,
                        );
                        switch (signed_txn) {
                            case (#Err(msg)) {
                                return #Err(msg);
                            };
                            case (#Ok({ signed_txn })) {
                                return #Ok({
                                    txn = signed_txn;
                                });
                            };
                        };
                    };
                };
            };
        };
    };

    /// Create a signed txn to transfer erc 20 with the provided parameters.
    public func transferErc20(
        lib : NoKeyWalletLib,
        caller_principal : Principal,
        chain_id : Nat64,
        max_priority_fee_per_gas : Nat64,
        gas_limit : Nat64,
        max_fee_per_gas : Nat64,
        address : [Nat8],
        value : Nat64,
        contract_address : [Nat8],
    ) : async Result<DeployContractResponse> {
        switch (State.getUserData(lib.state, caller_principal)) {
            case (null) {
                return #Err("User does not exist");
            };
            case (?userData) {
                let txn_chain_data = Map.get(userData.transactions, n64hash, chain_id);
                let nonce : Nat64 = switch (txn_chain_data) {
                    case (null) {
                        0;
                    };
                    case (?txn_chain_data) {
                        nat8ToNat64(txn_chain_data.last_nonce) + 1;
                    };
                };

                // TODO: encode the data.
                let data = [];

                let txn : Transaction = #EIP1559({
                    access_list = [];
                    chain_id = chain_id;
                    data = data;
                    max_fee_per_gas = nat64ToNat8(max_fee_per_gas);
                    max_priority_fee_per_gas = nat64ToNat8(max_priority_fee_per_gas);
                    gas_limit = nat64ToNat8(gas_limit);
                    sign = null;
                    to = nat64ToNat8(0);
                    value = nat64ToNat8(0);
                    nonce = nat64ToNat8(nonce);
                });

                let txn_encoded = await lib.evmUtil.create_transaction(txn);
                switch (txn_encoded) {
                    case (#Err(msg)) {
                        return #Err(msg);
                    };
                    case (#Ok(txn_encoded, _)) {
                        let signed_txn = await signTransaction(
                            lib,
                            txn_encoded,
                            chain_id,
                            caller_principal,
                            true,
                        );
                        switch (signed_txn) {
                            case (#Err(msg)) {
                                return #Err(msg);
                            };
                            case (#Ok({ signed_txn })) {
                                return #Ok({
                                    txn = signed_txn;
                                });
                            };
                        };
                    };
                };
            };
        };
    };

    private func nat64ToNat8(value : Nat64) : [Nat8] {
        return Binary.BigEndian.fromNat64(value);
    };

    private func nat8ToNat64(value : [Nat8]) : Nat64 {
        return Binary.BigEndian.toNat64(value);
    };
};
