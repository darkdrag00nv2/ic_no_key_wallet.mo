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

    public func createAddress(lib : NoKeyWalletLib, caller_principal : Principal) : async Result<CreateAddressResponse> {
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

    public func signTransaction(lib : NoKeyWalletLib, raw_txn : [Nat8], chain_id : Nat64, caller_principal : Principal, save_history : Bool) : async Result<Nat> {
        switch (State.getUserData(lib.state, caller_principal)) {
            case (null) {
                return #Err("The user does not exist");
            };
            case (?userData) {
                let txn = await lib.evmUtil.parse_transaction(raw_txn);

                switch (txn) {
                    case (#Err(msg)) { return #Err(msg) };
                    case (#Ok(txn)) {

                        #Err("TODO");
                    };
                };
            };
        };
    };

    private func getMessageToSign(txn : Transaction) {
        switch (txn) {
            case (#Legacy(txn_legacy)) {
                let buf = Buffer.Buffer<Nat8>(58);
                appendAllToBuffer(buf, txn_legacy.nonce);
                appendAllToBuffer(buf, txn_legacy.gas_price);
                appendAllToBuffer(buf, txn_legacy.gas_limit);
                appendAllToBuffer(buf, txn_legacy.to);
                appendAllToBuffer(buf, txn_legacy.value);
                appendAllToBuffer(buf, txn_legacy.data);
                appendAllToBuffer(buf, nat64_to_nat8(txn_legacy.chain_id));
            };
            case (#EIP2930(txn_2930)) {
                let buf = Buffer.Buffer<Nat8>(58);
                appendAllToBuffer(buf, nat64_to_nat8(txn_2930.chain_id));
                appendAllToBuffer(buf, txn_2930.nonce);
                appendAllToBuffer(buf, txn_2930.gas_price);
                appendAllToBuffer(buf, txn_2930.gas_limit);
                appendAllToBuffer(buf, txn_2930.to);
                appendAllToBuffer(buf, txn_2930.value);
                appendAllToBuffer(buf, txn_2930.data);
            };
            case (#EIP1559(txn_1559)) {
                let buf = Buffer.Buffer<Nat8>(58);
                appendAllToBuffer(buf, nat64_to_nat8(txn_1559.chain_id));
                appendAllToBuffer(buf, txn_1559.nonce);
                appendAllToBuffer(buf, txn_1559.max_priority_fee_per_gas);
                appendAllToBuffer(buf, txn_1559.max_fee_per_gas);
                appendAllToBuffer(buf, txn_1559.gas_limit);
                appendAllToBuffer(buf, txn_1559.to);
                appendAllToBuffer(buf, txn_1559.value);
                appendAllToBuffer(buf, txn_1559.data);
            };
        };
    };

    private func appendAllToBuffer<X>(buf : Buffer.Buffer<X>, values : [X]) {
        var i = 0;
        while (i < values.size()) {
            buf.add(values[i]);
            i += 1;
        };
    };

    public func nat64_to_nat8(n : Nat64) : [Nat8] {
        let buffer = Buffer.Buffer<Nat8>(8);

        var n_var = n;
        var i = 0;
        while (i < 8) {
            let val : Nat8 = Nat8.fromNat(Nat64.toNat(n_var % 256));
            buffer.add(val);
            n_var /= 256;
            i -= 1;
        };

        Buffer.reverse(buffer);
        return Buffer.toArray(buffer);
    };
};
