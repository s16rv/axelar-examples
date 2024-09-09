#!/bin/sh

DENOM=uaxl
CHAIN_ID=axelar
MONIKER=axelar
HOME_PATH=$HOME/.axelar
DIR="$(dirname "$0")"

MNEMONIC_RELAYER="use glove remain glance twin scout tank seminar purchase mix window illness"
MNEMONIC_RELAYER2="clown text faith prosper mushroom virtual decline chimney auto special differ garlic"

MNEMONIC_GOV1="rate cradle rescue rate still reveal rent brass high radar doctor drama cement another sick rug actual elbow fence orange salon motor walnut renew"
MNEMONIC_GOV2="season brief melt duck draw science tilt train april regret laptop rabbit pretty neck accuse glad stone armed convince math fever now improve wire"

OWNER="confirm boost crisp father lion act leisure opera iron wedding donate mixture pitch east differ famous picnic pen attract capital reform creek outer you"

# Removing the existing directory to start with a clean slate
rm -rf ${HOME_PATH}/*

DEFAULT_KEYS_FLAGS="--keyring-backend test --home ${HOME_PATH}"
ASSETS="100000000000000000000${DENOM}"

# Initializing a new blockchain with identifier ${CHAIN_ID} in the specified home directory
axelard init "$MONIKER" --chain-id ${CHAIN_ID} --home ${HOME_PATH} > /dev/null 2>&1 && echo "Initialized new blockchain with chain ID ${CHAIN_ID}"

# edit the app.toml file to enable the API and swagger
sed -i '/\[api\]/,/\[/ s/enable = false/enable = true/' "$HOME_PATH"/config/app.toml
sed -i '/\[api\]/,/\[/ s/swagger = false/swagger = true/' "$HOME_PATH"/config/app.toml

# staking/governance token is hardcoded in config, change this
sed -i "s/\"stake\"/\"$DENOM\"/" "$HOME_PATH"/config/genesis.json && echo "Updated staking token to $DENOM"

echo $MNEMONIC_RELAYER | axelard keys add relayer --recover ${DEFAULT_KEYS_FLAGS}
echo $MNEMONIC_RELAYER2 | axelard keys add relayer2 --recover ${DEFAULT_KEYS_FLAGS}

echo $MNEMONIC_GOV1 | axelard keys add gov1 --recover ${DEFAULT_KEYS_FLAGS}
echo "Added new key 'gov1'"
echo $MNEMONIC_GOV2 | axelard keys add gov2 --recover ${DEFAULT_KEYS_FLAGS}
echo "Added new key 'gov2'"

echo $OWNER | axelard keys add owner --recover ${DEFAULT_KEYS_FLAGS}
echo "Added new key 'owner'"

$(axelard keys add governance --multisig "gov1,gov2" --multisig-threshold 1 --nosort ${DEFAULT_KEYS_FLAGS} 2>&1 | tail -n 1)
echo "Added new key 'governance'"

# Adding a new genesis account named 'owner' with an initial balance of 100000000000000000000 in the blockchain
axelard add-genesis-account relayer ${ASSETS} \
--home ${HOME_PATH} \
--keyring-backend test > /dev/null 2>&1 && echo "Added 'relayer' to genesis account"

axelard add-genesis-account relayer2 ${ASSETS} \
--home ${HOME_PATH} \
--keyring-backend test > /dev/null 2>&1 && echo "Added 'relayer2' to genesis account"

axelard add-genesis-account owner ${ASSETS} \
--home ${HOME_PATH} \
--keyring-backend test > /dev/null 2>&1 && echo "Added 'owner' to genesis account"

axelard add-genesis-account gov1 ${ASSETS} \
--home ${HOME_PATH} \
--keyring-backend test > /dev/null 2>&1 && echo "Added 'gov1' to genesis account"

axelard add-genesis-account gov2 ${ASSETS} \
--home ${HOME_PATH} \
--keyring-backend test > /dev/null 2>&1 && echo "Added 'gov2' to genesis account"

axelard add-genesis-account governance ${ASSETS} \
--home ${HOME_PATH} \
--keyring-backend test > /dev/null 2>&1 && echo "Added 'governance' to genesis account"

axelard set-genesis-mint --inflation-min 0 --inflation-max 0 --inflation-max-rate-change 0 --home ${HOME_PATH}
axelard set-genesis-gov --minimum-deposit "100000000${DENOM}" --max-deposit-period 90s --voting-period 90s --home ${HOME_PATH}
axelard set-genesis-reward --external-chain-voting-inflation-rate 0 --home ${HOME_PATH}
axelard set-genesis-slashing --signed-blocks-window 35000 --min-signed-per-window 0.50 --home ${HOME_PATH} \
--downtime-jail-duration 600s --slash-fraction-double-sign 0.02 --slash-fraction-downtime 0.0001 --home ${HOME_PATH}
axelard set-genesis-snapshot --min-proxy-balance 5000000 --home ${HOME_PATH}
axelard set-genesis-staking  --unbonding-period 168h --max-validators 50 --bond-denom "$DENOM" --home ${HOME_PATH}
axelard set-genesis-chain-params evm Ethereum --evm-network-name ethereum --evm-chain-id 11155111 --network ethereum --confirmation-height 1 --revote-locking-period 5 --home ${HOME_PATH}

GOV_1_KEY="$(axelard keys show gov1 ${DEFAULT_KEYS_FLAGS} -p)"
GOV_2_KEY="$(axelard keys show gov2 ${DEFAULT_KEYS_FLAGS} -p)"
axelard set-governance-key 1 "$GOV_1_KEY" "$GOV_2_KEY" --home ${HOME_PATH}
axelard validate-genesis --home ${HOME_PATH}

# Generating a new genesis transaction for 'owner' delegating 100000000${DENOM} in the blockchain with the specified chain-id
axelard gentx owner 100000000${DENOM} \
--home ${HOME_PATH} \
--keyring-backend test \
--moniker ${MONIKER} \
--chain-id ${CHAIN_ID} > /dev/null 2>&1 && echo "Generated genesis transaction for 'owner'"

# Collecting all genesis transactions to form the genesis block
axelard collect-gentxs \
--home ${HOME_PATH} > /dev/null 2>&1 && echo "Collected genesis transactions"

# Read the content of the local file and append it to the file inside the Docker container
cat "${DIR}/libs/evm-rpc.toml" >> "$HOME_PATH"/config/config.toml

# Starting the blockchain node with the specified home directory
axelard start --log_level info --home ${HOME_PATH} \
--minimum-gas-prices 0${DENOM} \
--moniker ${MONIKER} \
--rpc.laddr "tcp://0.0.0.0:26657" \
--grpc.address "0.0.0.0:9090"

