/// An actor exposing the NoKeyWallet library functionalities.
///
/// This also serves as a reference implementation of the usage of the library.

import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";

import EvmUtil "../lib/EvmUtil";
import IcManagement "../lib/IcManagement";
import NoKeyWalletLib "../lib/NoKeyWalletLib";
import Types "../lib/Types";
import State "../lib/State";

actor NoKeyWallet {
  type EvmUtil = EvmUtil.EvmUtil;
  type IcManagement = IcManagement.IcManagement;

  type CreateAddressResponse = Types.CreateAddressResponse;
  type SignTransactionResponse = Types.SignTransactionResponse;
  type DeployContractResponse = Types.DeployContractResponse;
  type UserResponse = Types.UserResponse;
  type Result<X> = Types.Result<X>;

  type Env = State.Env;

  let evm_util : EvmUtil = actor ("ubgoy-tiaaa-aaaah-qc7qq-cai");
  let ic_management : IcManagement = actor ("aaaaa-aa");
  let env : Env = #Local;
  stable let lib = NoKeyWalletLib.init(evm_util, ic_management, env);

  /// Create an address/key for the caller principal.
  ///
  /// The address is saved in the user state and can be used later to sign a transaction.
  public shared (msg) func createAddress() : async Result<CreateAddressResponse> {
    return await NoKeyWalletLib.createAddress(lib, msg.caller);
  };

  /// Sign the provided raw transaction.
  ///
  /// The transaction will be signed for the provided chain_id.
  /// It will saved in the transaction history for the user if save_history is true.
  public shared (msg) func signTransaction(
    raw_txn : [Nat8],
    chain_id : Nat64,
    save_history : Bool,
  ) : async Result<SignTransactionResponse> {
    return await NoKeyWalletLib.signTransaction(lib, raw_txn, chain_id, msg.caller, save_history);
  };

  /// Get the transaction history of the caller for the provided chain_id.
  public shared (msg) func getCallerHistory(chain_id : Nat64) : async Result<UserResponse> {
    return await NoKeyWalletLib.getCallerHistory(lib, chain_id, msg.caller);
  };

  /// Clear the transaction history of the caller for the provided chain_id.
  public shared (msg) func clearCallerHistory(chain_id : Nat64) : async Result<()> {
    return await NoKeyWalletLib.clearCallerHistory(lib, chain_id, msg.caller);
  };

  /// Create a signed EVM contract with the provided parameters.
  public shared (msg) func deployEvmContract(
    bytecode : [Nat8],
    chain_id : Nat64,
    max_priority_fee_per_gas : Nat64,
    gas_limit : Nat64,
    max_fee_per_gas : Nat64,
  ) : async Result<DeployContractResponse> {
    return await NoKeyWalletLib.deployEvmContract(
      lib,
      msg.caller,
      bytecode,
      chain_id,
      max_priority_fee_per_gas,
      gas_limit,
      max_fee_per_gas,
    );
  };

  /// Create a signed txn to transfer erc 20 with the provided parameters.
  public shared (msg) func transferErc20(
    chain_id : Nat64,
    max_priority_fee_per_gas : Nat64,
    gas_limit : Nat64,
    max_fee_per_gas : Nat64,
    address : [Nat8],
    value : Nat64,
    contract_address : [Nat8],
  ) : async Result<DeployContractResponse> {
    return await NoKeyWalletLib.transferErc20(
      lib,
      msg.caller,
      chain_id,
      max_priority_fee_per_gas,
      gas_limit,
      max_fee_per_gas,
      address,
      value,
      contract_address,
    );
  };

  public query func healthcheck() : async Bool { true };
};
