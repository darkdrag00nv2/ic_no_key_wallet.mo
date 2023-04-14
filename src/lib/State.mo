import Map "mo:stable_hash_map/Map/Map";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";

module {
    type Map<K, V> = Map.Map<K, V>;
    let { phash } = Map;

    public type UserData = {
        var public_key : Blob;
    };

    public type State = {
        var users : Map<Principal, UserData>;
    };

    public func initUserData(pub_key: Blob) : UserData {
        { var public_key = pub_key }; 
    };

    public func initState() : State {
        let u = Map.new<Principal, UserData>(phash);
        { var users = u };
    };

    public func addUserPublicKey(s : State, p : Principal, pub_key : Blob) {
        let userData = initUserData(pub_key);
        ignore Map.put(s.users, phash, p, userData);
    };

    public func getUserData(s: State, p: Principal) : ?UserData {
        return Map.get(s.users, phash, p);
    };
};
