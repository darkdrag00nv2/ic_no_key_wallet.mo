module {
    public type CreateAddressResponse = {
        public_key: Blob;
    };

    public type Result<X> = {
        #Ok : X;
        #Err : Text;
    };
};
