import Map "mo:stable_hash_map/Map/Map";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import StableBuffer "mo:stable_buffer/StableBuffer";
import Time "mo:base/Time";

module {
    type Map<K, V> = Map.Map<K, V>;
    type StableBuffer<X> = StableBuffer.StableBuffer<X>;
    type Time = Time.Time;

    let { phash; n64hash } = Map;

    public type Env = {
        #Local;
        #Staging;
        #Production;
    };

    public type TransactionData = {
        data : [Nat8];
        timestamp : Time;
    };

    public type TransactionChainData = {
        var last_nonce : [Nat8];
        transactions : StableBuffer<TransactionData>;
    };

    public type UserData = {
        var public_key : Blob;
        var transactions : Map<Nat64, TransactionChainData>;
    };

    public type Config = {
        env : Env;
        key_name : Text;
        sign_cycles : Nat;
    };

    public type State = {
        var users : Map<Principal, UserData>;
        config : Config;
    };

    public func initUserData(pub_key : Blob) : UserData {
        {
            var public_key = pub_key;
            var transactions = Map.new<Nat64, TransactionChainData>(n64hash);
        };
    };

    public func initState(env : Env) : State {
        let config : Config = switch (env) {
            case (#Local) {
                {
                    env = env;
                    key_name = "dfx_test_key";
                    sign_cycles = 0;
                };
            };
            case (#Staging) {
                {
                    env = env;
                    key_name = "test_key_1";
                    sign_cycles = 10_000_000_000;
                };
            };
            case (#Production) {
                {
                    env = env;
                    key_name = "key_1";
                    sign_cycles = 26_153_846_153;
                };
            };
        };

        {
            var users = Map.new<Principal, UserData>(phash);
            config = config;
        };
    };

    public func getUserData(s : State, p : Principal) : ?UserData {
        return Map.get(s.users, phash, p);
    };

    public func addUserPublicKey(s : State, p : Principal, pub_key : Blob) {
        let userData = initUserData(pub_key);
        ignore Map.put(s.users, phash, p, userData);
    };

    public func addTransactionForUser(
        s : State,
        p : Principal,
        txn_data : TransactionData,
        chain_id : Nat64,
        nonce : [Nat8],
    ) {
        let userData = getUserData(s, p);
        ignore do ? {
            if (Map.has(userData!.transactions, n64hash, chain_id)) {
                var txn_chain_data = Map.get(userData!.transactions, n64hash, chain_id);
                txn_chain_data!.last_nonce := nonce;
                StableBuffer.add(txn_chain_data!.transactions, txn_data);
            } else {
                let txn_chain_data = {
                    var last_nonce = nonce;
                    transactions = StableBuffer.init<TransactionData>();
                };
                StableBuffer.add(txn_chain_data.transactions, txn_data);
                ignore Map.put(userData!.transactions, n64hash, chain_id, txn_chain_data);
            };
        };
    };
};
