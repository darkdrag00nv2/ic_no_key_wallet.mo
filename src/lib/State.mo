import Map "mo:stable_hash_map/Map/Map";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import StableBuffer "mo:stable_buffer/StableBuffer";

module {
    type Map<K, V> = Map.Map<K, V>;
    type StableBuffer<X> = StableBuffer.StableBuffer<X>;

    let { phash; n64hash } = Map;

    public type Transaction = {
        data : [Nat8];
        timestamp : Nat64;
    };

    public type TransactionChainData = {
        nonce : [Nat8];
        transactions : StableBuffer<Transaction>;
    };

    public type UserData = {
        var public_key : Blob;
        var transactions : Map<Nat64, TransactionChainData>;
    };

    public type State = {
        var users : Map<Principal, UserData>;
    };

    public func initUserData(pub_key : Blob) : UserData {
        {
            var public_key = pub_key;
            var transactions = Map.new<Nat64, TransactionChainData>(n64hash);
        };
    };

    public func initState() : State {
        { var users = Map.new<Principal, UserData>(phash) };
    };

    public func addUserPublicKey(s : State, p : Principal, pub_key : Blob) {
        let userData = initUserData(pub_key);
        ignore Map.put(s.users, phash, p, userData);
    };

    public func getUserData(s : State, p : Principal) : ?UserData {
        return Map.get(s.users, phash, p);
    };
};
