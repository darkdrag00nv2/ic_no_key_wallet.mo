module {
    public type CreateAddressResponse = {};

    public type Result<X> = {
        #Ok : X;
        #Err : Text;
    };
};
