#!/bin/bash

CHAIN_ID=axelar
HOME_PATH="$HOME/.axelar"
DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"

# Define paths
UNSIGNED_MSG_PATH="${HOME_PATH}/unsigned_msg.json"
SIGNED_TX_PATH="${HOME_PATH}/signed_tx.json"
TX_MS_PATH="${HOME_PATH}/tx-ms.json"
MULTISIG_ADDRESS=$(axelard keys show governance -a ${DEFAULT_KEYS_FLAGS})

if [ $? -ne 0 ]; then
  echo "Failed to retrieve multisig address"
  exit 1
fi

# Sign the transaction
if ! axelard tx sign "${HOME_PATH}/unsigned_msg.json" --from gov1 \
  --multisig "$MULTISIG_ADDRESS" \
  --chain-id "$CHAIN_ID" ${DEFAULT_KEYS_FLAGS} > "${HOME_PATH}/signed_tx.json" 2>&1; then
  echo "Failed to sign transaction. Check ${HOME_PATH}/signed_tx.json for details."
  exit 1
fi

# Multisign the signed transaction
if ! axelard tx multisign "$UNSIGNED_MSG_PATH" governance "$SIGNED_TX_PATH" \
  --chain-id "$CHAIN_ID" ${DEFAULT_KEYS_FLAGS} > "$TX_MS_PATH" 2>&1; then
  echo "Failed to multisign transaction. Check $TX_MS_PATH for details."
  exit 1
fi

# Broadcast the transaction
if ! axelard tx broadcast "$TX_MS_PATH" ${DEFAULT_KEYS_FLAGS} > "${HOME_PATH}/broadcast_output.json" 2>&1; then
  echo "Failed to broadcast transaction. Check ${HOME_PATH}/broadcast_output.json for details."
  exit 1
fi

cat "${HOME_PATH}/broadcast_output.json"