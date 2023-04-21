let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.7-20230406/package-set.dhall sha256:cb4ea443519a950c08db572738173a30d37fb096e32bc98f35b78436bae1cd17
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [
      {
        name = "stable_hash_map",
        repo = "https://github.com/ZhenyaUsenko/motoko-hash-map",
        version = "v8.1.0",
        dependencies = [ "base" ]
      },
      { name = "stable_buffer", 
        repo = "https://github.com/canscale/StableBuffer",
        version = "v1.0.0",
        dependencies = [ "base"]
      },
      { name = "base-0.7.3", repo = "https://github.com/dfinity/motoko-base.git", version = "moc-0.7.4", dependencies = []: List Text },
      { name = "encoding", 
        repo = "https://github.com/aviate-labs/encoding.mo",
        version = "v0.4.1",
        dependencies = [ "base-0.7.3"]
      },
    ] : List Package

let
  overrides =
    [] : List Package

in  upstream # additions # overrides
