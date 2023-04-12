import EvmUtil "lib/EvmUtil";
import Lib "lib/Lib";

actor NoKeyWallet {
  type EvmUtil = EvmUtil.EvmUtil;

  // TODO: https://forum.dfinity.org/t/env-variables-for-motoko-builds/11640/8
  let evm_util : EvmUtil = actor ("ubgoy-tiaaa-aaaah-qc7qq-cai");
  let lib = Lib.NoKeyWalletLib(evm_util);

  public func healthcheck() : async Bool { true };

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };
};
