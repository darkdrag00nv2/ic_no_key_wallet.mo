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

module {
    type EvmUtil = EvmUtil.EvmUtil;
    type IcManagement = IcManagement.IcManagement;
    type CreateAddressResponse = Types.CreateAddressResponse;
    type SignTransactionResponse = Types.SignTransactionResponse;
    type Result<X> = Types.Result<X>;
    type State = State.State;
    type UserData = State.UserData;
    type Transaction = EvmUtil.Transaction;
    type TransactionData = State.TransactionData;

    public type NoKeyWalletLib = {
        evmUtil : EvmUtil;
        icManagement : IcManagement;
        state : State;
    };

    public func init(initEvmUtil : EvmUtil, initIcManagement : IcManagement) : NoKeyWalletLib = {
        evmUtil = initEvmUtil;
        icManagement = initIcManagement;
        state = State.initState();
    };

    /// Create an address for the provided principal.
    ///
    /// The address is saved in the user state and can be used later to sign a transaction.
    public func createAddress(
        lib : NoKeyWalletLib,
        caller_principal : Principal,
    ) : async Result<CreateAddressResponse> {
        try {
            // TODO: Use key name based on the environment.
            let { public_key } = await lib.icManagement.ecdsa_public_key({
                canister_id = null;
                derivation_path = [Principal.toBlob(caller_principal)];
                key_id = { curve = #secp256k1; name = "dfx_test_key" };
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
                            // TODO: Use cycle amount and key name based on the environment.
                            Cycles.add(10_000_000_000);
                            let { signature } = await lib.icManagement.sign_with_ecdsa({
                                message_hash = Blob.fromArray(message_hash);
                                derivation_path = [Principal.toBlob(caller_principal)];
                                key_id = {
                                    curve = #secp256k1;
                                    name = "dfx_test_key";
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

        switch (txn) {
            case (#Legacy(txn_legacy)) {
                let r = Array.subArray(sig_bytes, 0, 4);
                let s = Array.subArray(sig_bytes, 4, 4);
                let recovery_id = await getRecoveryId(lib, msg_hash, sig_bytes, public_key_bytes);
                switch (recovery_id) {
                    case (#Err(msg)) {
                        return #Err(msg);
                    };
                    case (#Ok(recovery_id)) {
                        let v = chain_id * 2 + 35 + Nat64.fromNat(Nat8.toNat(recovery_id));
                    };
                };
            };
            case (#EIP1559(txn_1559)) {};
            case (#EIP2930(txn_2930)) {};
        };

        #Err("TODO");
    };

    private func getRecoveryId(
        lib : NoKeyWalletLib,
        msg_hash : [Nat8],
        sig_bytes : [Nat8],
        public_key_bytes : [Nat8],
    ) : async Result<Nat8> {

        return #Err("TODO");
    };

    private func cloneTransactionWithSignatureInfo() {

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
};
