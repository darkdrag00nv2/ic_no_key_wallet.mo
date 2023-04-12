/// Wallet support for Evm-based chains.
///
/// TODO: Add more details
import EvmUtil "EvmUtil";

module {
    type EvmUtil = EvmUtil.EvmUtil;

    public class NoKeyWalletLib(init: EvmUtil) {
        var evm_util : EvmUtil = init;
    };
};
