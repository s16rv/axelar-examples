# !/bin/bash

docker run --rm -v "$(pwd)/examples/cosmos/call-contract/wasm-contract":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/code/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/rust-optimizer:0.12.13

docker run --rm -v "$(pwd)/examples/cosmos/call-contract/wasm-contract-neutron":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/code/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/rust-optimizer:0.16.0

docker run --rm -v "$(pwd)/examples/cosmos/smart-account/wasm-contract-neutron":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/code/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/rust-optimizer:0.16.0

