#!/bin/sh

EVM_CHAIN=ethereum
COSMOS_CHAIN=cosmos
DIR="$(dirname "$0")"

echo "#### 1. Adding EVM chain ####"
"${DIR}/steps/01-add-evm-chain.sh" ${EVM_CHAIN}

echo "\n#### 2. Adding Cosmos chain ####"
"${DIR}/steps/02-add-cosmos-chain.sh" ${COSMOS_CHAIN}

echo "\n#### 3. Register Broadcaster ####"
"${DIR}/steps/03-register-broadcaster.sh"

echo "\n#### 4. Activate EVM Chains ####"
"${DIR}/steps/04-activate-evm-chain.sh" ${EVM_CHAIN}

echo "\n#### 5. Activate Cosmos Chains ####"
"${DIR}/steps/05-activate-cosmos-chain.sh" ${COSMOS_CHAIN}
