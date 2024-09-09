#!/bin/bash

CHAIN_ID="axelar"
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"

if ! axelard tx multisig rotate ethereum key1 \
  --chain-id "${CHAIN_ID}" --from gov1 --home "${HOME_PATH}" \
  --output json --gas 500000 ${DEFAULT_KEYS_FLAGS}; then
  echo "Failed to sign message."
  exit 1
fi

echo "Successfully setup keygen"