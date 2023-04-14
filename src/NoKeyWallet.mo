import EvmUtil "lib/EvmUtil";
import IcManagement "lib/IcManagement";
import NoKeyWalletLib "lib/Lib";
import Types "lib/Types";
import Principal "mo:base/Principal";

actor NoKeyWallet {
  type EvmUtil = EvmUtil.EvmUtil;
  type IcManagement = IcManagement.IcManagement;
  type CreateAddressResponse = Types.CreateAddressResponse;
  type Result<X> = Types.Result<X>;

  // TODO: https://forum.dfinity.org/t/env-variables-for-motoko-builds/11640/8
  let evm_util : EvmUtil = actor ("ubgoy-tiaaa-aaaah-qc7qq-cai");
  let ic_management : IcManagement = actor ("aaaaa-aa");
  stable let lib = NoKeyWalletLib.init(evm_util, ic_management);

  public shared (msg) func createAddress() : async Result<CreateAddressResponse> {
    return await NoKeyWalletLib.createAddress(lib, msg.caller);
  };

  public shared (msg) func signTransaction(raw_txn : [Nat8], chain_id : Nat64, save_history : Bool) : async Result<Nat> {
    return await NoKeyWalletLib.signTransaction(lib, raw_txn, chain_id, msg.caller, save_history);
  };

  public query func healthcheck() : async Bool { true };
};
