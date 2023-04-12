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

module {
    type EvmUtil = EvmUtil.EvmUtil;
    type IcManagement = IcManagement.IcManagement;
    type CreateAddressResponse = Types.CreateAddressResponse;
    type Result<X> = Types.Result<X>;
    type State = State.State;

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
};
