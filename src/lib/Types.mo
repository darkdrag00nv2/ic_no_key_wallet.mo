/// Type declarations for the library.

import State "State";

module {
    public type CreateAddressResponse = {
        address : [Nat8];
    };

    public type SignTransactionResponse = {
        signed_txn : [Nat8];
    };

    public type DeployContractResponse = {
        txn : [Nat8];
    };

    public type UserResponse = {
        address : [Nat8];
        transactions : ?TransactionData;
    };

    // Equivalent to State.TransactionChainData but with an array instead of StableBuffer.
    public type TransactionData = {
        last_nonce : [Nat8];
        transactions : [State.TransactionData];
    };

    public type Result<X> = {
        #Ok : X;
        #Err : Text;
    };
};
