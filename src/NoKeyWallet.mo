import EvmUtil "lib/EvmUtil";
import IcManagement "lib/IcManagement";
import Lib "lib/Lib";
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
  let lib = Lib.NoKeyWalletLib(evm_util, ic_management);

  public shared (msg) func createAddress() : async Result<CreateAddressResponse> {
    let caller = Principal.toBlob(msg.caller);
    return await lib.createAddress(caller);
  };

  public query func healthcheck() : async Bool { true };
};
