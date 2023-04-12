/// Wallet support for Evm-based chains.
///
/// TODO: Add more details
import EvmUtil "EvmUtil";
import Types "Types";
import Principal "mo:base/Principal";
import IcManagement "IcManagement";
import Error "mo:base/Error";
import Blob "mo:base/Blob";

module {
    type EvmUtil = EvmUtil.EvmUtil;
    type IcManagement = IcManagement.IcManagement;
    type CreateAddressResponse = Types.CreateAddressResponse;
    type Result<X> = Types.Result<X>;

    public class NoKeyWalletLib(initEvmUtil : EvmUtil, initIcManagement : IcManagement) {
        var evm_util : EvmUtil = initEvmUtil;
        var ic_management : IcManagement = initIcManagement;

        public func createAddress(caller_id : Blob) : async Result<CreateAddressResponse> {
            try {
                // TODO: Use key name based on the environment.
                let { public_key } = await ic_management.ecdsa_public_key({
                    canister_id = null;
                    derivation_path = [caller_id];
                    key_id = { curve = #secp256k1; name = "dfx_test_key" };
                });

                let address_or_error = await evm_util.pub_to_address(Blob.toArray(public_key));
                switch (address_or_error) {
                    case (#Ok(pub_key)) { return #Ok({ public_key }) };
                    case (#Err(msg)) { return #Err(msg) };
                };

                // TODO: Maintain the user state and push the newly created data into it.
            } catch (err) {
                #Err(Error.message(err));
            };
        };
    };
};
