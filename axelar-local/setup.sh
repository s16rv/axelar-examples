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

echo "\n#### 6. Register Controller ####"
"${DIR}/steps/06-register-controller.sh"

echo "\n#### 7. Setup keygen ####"
"${DIR}/steps/07-setup-keygen.sh"

echo "\n#### Waiting 10 seconds before rotating keygen ####"
sleep 10

echo "\n#### 8. Rotate keygen ####"
"${DIR}/steps/08-rotate-keygen.sh"

echo "\n#### Waiting 10 seconds before registering gateway ####"
sleep 10

echo "\n#### 9. Register gateway ethereum ####"
"${DIR}/steps/09-register-gateway-ethereum.sh"