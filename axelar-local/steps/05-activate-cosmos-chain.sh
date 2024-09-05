#!/bin/bash

# Set the chain variable, defaulting to 'cosmos' if not provided
CHAIN="${1:-cosmos}"
DIR="$(dirname "$0")"

# Define the path to the activate-chain.sh script
ACTIVATE_CHAIN_SCRIPT="$DIR/../libs/activate-chain.sh"

# Check if the activate-chain.sh script exists and is executable
if [ ! -x "$ACTIVATE_CHAIN_SCRIPT" ]; then
  echo "Error: activate-chain.sh script not found or not executable at ${ACTIVATE_CHAIN_SCRIPT}."
  exit 1
fi

# Execute the activate-chain.sh script with the specified chain
if ! sh "$ACTIVATE_CHAIN_SCRIPT" "$CHAIN"; then
  echo "Error: Failed to execute $ACTIVATE_CHAIN_SCRIPT with chain $CHAIN."
  exit 1
fi

echo "Successfully executed $ACTIVATE_CHAIN_SCRIPT with chain $CHAIN."
