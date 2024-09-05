#!/bin/bash

CHAIN_ID="axelar"
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"
CHAIN="${1:-cosmos}"
CHANNEL_ID="${2:-channel-0}"
DIR="$(dirname "$0")"

# Ensure chain name is provided
if [ -z "$CHAIN" ]; then
  echo "Chain name is required"
  exit 1
fi

# Create the transaction
if ! axelard tx axelarnet add-cosmos-based-chain "$CHAIN" "$CHAIN" "transfer/${CHANNEL_ID}" --generate-only \
  --chain-id "$CHAIN_ID" --from "$(axelard keys show governance -a ${DEFAULT_KEYS_FLAGS})" --home "$HOME_PATH" \
  --output json --gas 500000 &> "${HOME_PATH}/unsigned_msg.json"; then
  echo "Failed to generate unsigned message. Check ${HOME_PATH}/unsigned_msg.json for details."
  exit 1
fi

# Ensure the broadcast script exists and is executable
BROADCAST_SCRIPT="$DIR/../libs/broadcast-unsigned-multi-tx.sh"
if [ ! -x "$BROADCAST_SCRIPT" ]; then
  echo "Broadcast script not found or not executable: $BROADCAST_SCRIPT"
  exit 1
fi

# Run the broadcast script
if ! sh "$BROADCAST_SCRIPT"; then
  echo "Failed to execute broadcast script"
  exit 1
fi

echo "Successfully added chain $CHAIN."