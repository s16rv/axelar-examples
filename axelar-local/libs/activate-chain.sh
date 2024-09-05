#!/bin/bash

CHAIN_ID="axelar"
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"
CHAIN="$1"
DIR="$(dirname "$0")"

# Ensure a chain name is provided
if [ -z "$CHAIN" ]; then
  echo "Error: Chain name is required."
  exit 1
fi

# Generate unsigned message
if ! axelard tx nexus activate-chain "$CHAIN" --generate-only \
  --chain-id "$CHAIN_ID" --from "$(axelard keys show governance -a ${DEFAULT_KEYS_FLAGS})" --home "$HOME_PATH" \
  --output json --gas 500000 > "${HOME_PATH}/unsigned_msg.json"; then
  echo "Error: Failed to generate unsigned message."
  exit 1
fi

# Display the unsigned message
echo "Unsigned message generated:"
cat "${HOME_PATH}/unsigned_msg.json"

# Ensure the broadcast script exists and is executable
BROADCAST_SCRIPT="$DIR/broadcast-unsigned-multi-tx.sh"
if [ ! -x "$BROADCAST_SCRIPT" ]; then
  echo "Error: Broadcast script not found or not executable: $BROADCAST_SCRIPT"
  exit 1
fi

# Execute the broadcast script
if ! sh "$BROADCAST_SCRIPT"; then
  echo "Error: Failed to execute broadcast script: $BROADCAST_SCRIPT"
  exit 1
fi

echo "Successfully executed all steps."
