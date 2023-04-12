/// Wallet support for Evm-based chains.
///
/// TODO: Add more details
import EvmUtil "EvmUtil";
import Types "Types";
import Principal "mo:base/Principal";
import IcManagement "IcManagement";

module {
    type EvmUtil = EvmUtil.EvmUtil;
    type IcManagement = IcManagement.IcManagement;
    type CreateAddressResponse = Types.CreateAddressResponse;
    type Result<X> = Types.Result<X>;

    public class NoKeyWalletLib(initEvmUtil : EvmUtil, initIcManagement : IcManagement) {
        var evm_util : EvmUtil = initEvmUtil;
        var ic_management : IcManagement = initIcManagement;

        public func createAddress(caller_id : Blob) : async Result<CreateAddressResponse> {
            return #Ok({});
        };
    };
};
