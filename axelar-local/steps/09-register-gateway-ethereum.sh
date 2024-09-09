#!/bin/bash

CHAIN_ID="axelar"
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"
DIR="$(dirname "$0")"
GATEWAY_ADDRESS="0xe432150cce91c13a887f7D836923d5597adD8E31"

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
if ! axelard tx evm set-gateway ethereum "$GATEWAY_ADDRESS" --generate-only \
  --chain-id "${CHAIN_ID}" --from "$GOVERNANCE_ADDRESS" --home "${HOME_PATH}" \
  --output json --gas 500000 | jq &> "${HOME_PATH}/unsigned_msg.json"; then
  echo "Failed to generate unsigned message. Check ${HOME_PATH}/unsigned_msg.json for details."
  exit 1
fi

# Run the broadcast script
if ! sh "$BROADCAST_SCRIPT"; then
  echo "Failed to execute broadcast script"
  exit 1
fi

echo "Successfully set gateway"