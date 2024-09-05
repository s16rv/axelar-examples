#!/bin/bash

CHAIN_ID="axelar"
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"
DIR="$(dirname "$0")"

# Retrieve the address for gov1
GOV1_ADDRESS=$(axelard keys show gov1 -a ${DEFAULT_KEYS_FLAGS})
if [ $? -ne 0 ]; then
  echo "Failed to retrieve address for gov1. Please check your axelard configuration."
  exit 1
fi

# Register proxy
if ! axelard tx snapshot register-proxy "$GOV1_ADDRESS" \
  --chain-id "$CHAIN_ID" --from owner ${DEFAULT_KEYS_FLAGS} \
  --output json --gas 1000000 &> "${HOME_PATH}/register_proxy_output.json"; then
  echo "Failed to register proxy. Check ${HOME_PATH}/register_proxy_output.json for details."
  exit 1
fi

# Register chain maintainers
if ! axelard tx nexus register-chain-maintainer avalanche ethereum fantom moonbeam polygon \
  --chain-id "$CHAIN_ID" --from gov1 ${DEFAULT_KEYS_FLAGS} \
  --output json --gas 1000000 &> "${HOME_PATH}/register_chain_maintainer_output.json"; then
  echo "Failed to register chain maintainers. Check ${HOME_PATH}/register_chain_maintainer_output.json for details."
  exit 1
fi

echo "Successfully registered proxy and chain maintainers."
