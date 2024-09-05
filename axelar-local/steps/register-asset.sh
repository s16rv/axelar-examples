#!/bin/sh

CHAIN_ID="axelar"
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"
CHAIN="$1"
DENOM="${2:-ualpha}"
DIR="$(dirname "$0")"

# Ensure chain name is provided
if [ -z "$CHAIN" ]; then
  echo "Chain name is required."
  exit 1
fi

# Display what is being registered
echo "Registering asset ${CHAIN} ${DENOM}"

# Register the asset
if ! axelard tx axelarnet register-asset "$CHAIN" "$DENOM" --is-native-asset --generate-only \
  --chain-id "$CHAIN_ID" --from "$(axelard keys show governance -a ${DEFAULT_KEYS_FLAGS})" ${DEFAULT_KEYS_FLAGS} \
  --output json --gas 500000 &> "${HOME_PATH}/unsigned_msg.json"; then
  echo "Failed to register asset ${CHAIN} ${DENOM}. Check ${HOME_PATH}/unsigned_msg.json for details."
  exit 1
fi

# Display the unsigned message
cat "${HOME_PATH}/unsigned_msg.json"
echo "Successfully registered asset ${CHAIN} ${DENOM}"

# Ensure the broadcast script exists and is executable
BROADCAST_SCRIPT="$DIR/../libs/broadcast-unsigned-multi-tx.sh"
if [ ! -x "$BROADCAST_SCRIPT" ]; then
  echo "Broadcast script not found or not executable: $BROADCAST_SCRIPT"
  exit 1
fi

# Execute the broadcast script
if ! sh "$BROADCAST_SCRIPT"; then
  echo "Failed to execute broadcast script: $BROADCAST_SCRIPT"
  exit 1
fi
