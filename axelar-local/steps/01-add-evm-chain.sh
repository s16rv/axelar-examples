#!/bin/bash

CHAIN_ID="axelar"
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"
CHAIN="${1:-ethereum}"
DIR="$(dirname "$0")"

# Ensure chain name is provided
if [ -z "$CHAIN" ]; then
  echo "Chain name is required."
  exit 1
fi

# Ensure the params.json file exists
PARAMS_FILE="${DIR}/../libs/params.json"
if [ ! -f "$PARAMS_FILE" ]; then
  echo "params.json file not found at ${PARAMS_FILE}."
  exit 1
fi

# Ensure the broadcast script exists and is executable
BROADCAST_SCRIPT="${DIR}/../libs/broadcast-unsigned-multi-tx.sh"
if [ ! -x "$BROADCAST_SCRIPT" ]; then
  echo "broadcast-unsigned-multi-tx.sh script not found or not executable at ${BROADCAST_SCRIPT}."
  exit 1
fi

# Retrieve the governance key address
GOVERNANCE_ADDRESS=$(axelard keys show governance -a ${DEFAULT_KEYS_FLAGS})
if [ $? -ne 0 ]; then
  echo "Failed to retrieve governance key address. Please check your axelard configuration."
  exit 1
fi

# Generate the unsigned message
if ! axelard tx evm add-chain "${CHAIN}" "$PARAMS_FILE" --generate-only \
  --chain-id "${CHAIN_ID}" --from "$GOVERNANCE_ADDRESS" --home "${HOME_PATH}" \
  --output json --gas 500000 &> "${HOME_PATH}/unsigned_msg.json"; then
  echo "Failed to generate unsigned message. Check ${HOME_PATH}/unsigned_msg.json for details."
  exit 1
fi

# Run the broadcast script
if ! sh "$BROADCAST_SCRIPT"; then
  echo "Failed to execute broadcast script"
  exit 1
fi

echo "Successfully added chain $CHAIN."