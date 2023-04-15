module {
    public type CreateAddressResponse = {
        address: [Nat8];
    };

    public type SignTransactionResponse = {
        signed_txn: [Nat8];
    };

    public type Result<X> = {
        #Ok : X;
        #Err : Text;
    };
};
