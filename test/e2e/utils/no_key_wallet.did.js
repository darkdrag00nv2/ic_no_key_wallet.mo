export const idlFactory = ({ IDL }) => {
  const Result_4 = IDL.Variant({ 'Ok' : IDL.Null, 'Err' : IDL.Text });
  const CreateAddressResponse = IDL.Record({ 'address' : IDL.Vec(IDL.Nat8) });
  const Result_3 = IDL.Variant({
    'Ok' : CreateAddressResponse,
    'Err' : IDL.Text,
  });
  const DeployContractResponse = IDL.Record({ 'txn' : IDL.Vec(IDL.Nat8) });
  const Result = IDL.Variant({
    'Ok' : DeployContractResponse,
    'Err' : IDL.Text,
  });
  const Time = IDL.Int;
  const TransactionData__1 = IDL.Record({
    'data' : IDL.Vec(IDL.Nat8),
    'timestamp' : Time,
  });
  const TransactionData = IDL.Record({
    'last_nonce' : IDL.Vec(IDL.Nat8),
    'transactions' : IDL.Vec(TransactionData__1),
  });
  const UserResponse = IDL.Record({
    'address' : IDL.Vec(IDL.Nat8),
    'transactions' : IDL.Opt(TransactionData),
  });
  const Result_2 = IDL.Variant({ 'Ok' : UserResponse, 'Err' : IDL.Text });
  const SignTransactionResponse = IDL.Record({
    'signed_txn' : IDL.Vec(IDL.Nat8),
  });
  const Result_1 = IDL.Variant({
    'Ok' : SignTransactionResponse,
    'Err' : IDL.Text,
  });
  return IDL.Service({
    'clearCallerHistory' : IDL.Func([IDL.Nat64], [Result_4], []),
    'createAddress' : IDL.Func([], [Result_3], []),
    'deployEvmContract' : IDL.Func(
        [IDL.Vec(IDL.Nat8), IDL.Nat64, IDL.Nat64, IDL.Nat64, IDL.Nat64],
        [Result],
        [],
      ),
    'getCallerHistory' : IDL.Func([IDL.Nat64], [Result_2], []),
    'healthcheck' : IDL.Func([], [IDL.Bool], ['query']),
    'signTransaction' : IDL.Func(
        [IDL.Vec(IDL.Nat8), IDL.Nat64, IDL.Bool],
        [Result_1],
        [],
      ),
    'transferErc20' : IDL.Func(
        [
          IDL.Nat64,
          IDL.Nat64,
          IDL.Nat64,
          IDL.Nat64,
          IDL.Vec(IDL.Nat8),
          IDL.Nat64,
          IDL.Vec(IDL.Nat8),
        ],
        [Result],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
