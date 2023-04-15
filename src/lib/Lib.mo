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

module {
    type EvmUtil = EvmUtil.EvmUtil;
    type IcManagement = IcManagement.IcManagement;
    type CreateAddressResponse = Types.CreateAddressResponse;
    type Result<X> = Types.Result<X>;
    type State = State.State;
    type UserData = State.UserData;
    type Transaction = EvmUtil.Transaction;

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

    public func signTransaction(
        lib : NoKeyWalletLib,
        raw_txn : [Nat8],
        chain_id : Nat64,
        caller_principal : Principal,
        save_history : Bool,
    ) : async Result<Nat> {
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

                            let signed_txn_serialized = await signTransactionWithSignature(lib, txn, signature);
                        } catch (err) {
                            return #Err(Error.message(err));
                        };

                        #Ok(0);
                    };
                };
            };
        };
    };

    private func signTransactionWithSignature(
        lib : NoKeyWalletLib,
        txn : Transaction,
        signature : Blob,
    ) : async Result<Nat> {
        #Err("TODO");
    };
};
