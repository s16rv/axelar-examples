use cosmwasm_std::to_json_binary;
#[cfg(not(feature = "library"))]
use cosmwasm_std::{Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult};
use ethabi::ethereum_types::U256;
use ethabi::{encode, Token};
use neutron_sdk::bindings::msg::IbcFee;
use neutron_sdk::bindings::msg::NeutronMsg;
use neutron_sdk::bindings::query::NeutronQuery;
use neutron_sdk::NeutronResult;
use serde_json_wasm::to_string;
use crate::state::{Config, CONFIG};

// use cw2::set_contract_version;

use crate::error::ContractError;
use crate::msg::*;
use crate::state::*;

/*
// version info for migration info
const CONTRACT_NAME: &str = "crates.io:send-receive";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");
*/

// Neutron Fee Denom
const FEE_DENOM: &str = "untrn";

// Axelar relayer address to use as the fee recipient
// https://github.com/axelarnetwork/evm-cosmos-gmp-sample/blob/main/native-integration/README.md#relayer-service-for-cosmos---evm
const AXELAR_FEE_RECIPIENT: &str = "axelar1zl3rxpp70lmte2xr6c4lgske2fyuj3hupcsvcd";

const AXELAR_GMP_ADDRESS: &str = "axelar1dv4u5k73pzqrxlzujxg3qp8kvc3pje7jtdvu72npnt5zhq05ejcsn5qme5";

enum Transaction {
    CreateAccount = 1,
    // HandleTransaction = 2,
}

impl Transaction {
    fn to_uint(&self) -> U256 {
        match self {
            Transaction::CreateAccount => U256::from(1),
            // Transaction::HandleTransaction => U256::from(2),
        }
    }
}

pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let cfg = Config {
        channel: msg.channel,
    };

    CONFIG.save(deps.storage, &cfg)?;

    Ok(Response::default())
}

pub fn execute(
    deps:  DepsMut<NeutronQuery>,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> NeutronResult<Response<NeutronMsg>> {
    use ExecuteMsg::*;

    match msg {
        CreateAccountEvm {
            destination_chain,
            destination_address,
            address,
        } => exec::create_account_evm(
            deps,
            env,
            info,
            destination_chain,
            destination_address,
            address,
        ),
        SendTransactionEvm { destination_chain, destination_address, address, data } => todo!(),
    }
}

mod exec {
    use cw_utils::one_coin;
    use neutron_sdk::{bindings::{msg::NeutronMsg, query::NeutronQuery}, query::min_ibc_fee::query_min_ibc_fee, sudo::msg::RequestPacketTimeoutHeight, NeutronResult};

    use super::*;

    pub fn create_account_evm(
        deps: DepsMut<NeutronQuery>,
        env: Env,
        info: MessageInfo,
        destination_chain: String,
        destination_address: String,
        owner: String,
    ) -> NeutronResult<Response<NeutronMsg>> {
        // Message payload to be received by the destination
        let message_payload = encode(&vec![
            Token::Uint(Transaction::CreateAccount.to_uint()),
            Token::String(owner),
        ]);

        // {info.funds} used to pay gas. Must only contain 1 token type.
        let coin: cosmwasm_std::Coin = one_coin(&info).unwrap();

        let fee: Option<Fee> = Some(Fee {
            amount: coin.amount.to_string(),
            recipient: AXELAR_FEE_RECIPIENT.to_string(),
        });

        let gmp_message: GmpMessage = GmpMessage {
            destination_chain,
            destination_address,
            payload: message_payload.to_vec(),
            type_: 1,
            fee,
        };

        let config = CONFIG.load(deps.storage)?;

        let fee = min_ntrn_ibc_fee(query_min_ibc_fee(deps.as_ref())?.min_fee);
        let ibc_message = NeutronMsg::IbcTransfer {
            source_port: "transfer".to_string(),
            source_channel: config.channel.to_string(),
            token: coin,
            sender: env.contract.address.to_string(),
            receiver: AXELAR_GMP_ADDRESS.to_string(),
            timeout_height: RequestPacketTimeoutHeight {
                revision_height: Some(0),
                revision_number: Some(0),
            },
            timeout_timestamp: env.block.time.plus_seconds(604_800u64).nanos(),
            memo: to_string(&gmp_message).unwrap(),
            fee,
        };

        Ok(Response::new().add_message(ibc_message))
    }
}

pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    use QueryMsg::*;

    match msg {
        GetStoredMessage {} => to_json_binary(&query::get_stored_message(deps)?),
    }
}

mod query {
    use super::*;

    pub fn get_stored_message(deps: Deps) -> StdResult<GetStoredMessageResp> {
        let message = STORED_MESSAGE.may_load(deps.storage).unwrap().unwrap();
        let resp = GetStoredMessageResp {
            sender: message.sender,
            message: message.message,
        };
        Ok(resp)
    }
}

fn min_ntrn_ibc_fee(fee: IbcFee) -> IbcFee {
    IbcFee {
        recv_fee: fee.recv_fee,
        ack_fee: fee
            .ack_fee
            .into_iter()
            .filter(|a| a.denom == FEE_DENOM)
            .collect(),
        timeout_fee: fee
            .timeout_fee
            .into_iter()
            .filter(|a| a.denom == FEE_DENOM)
            .collect(),
    }
}