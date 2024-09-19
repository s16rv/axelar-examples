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

const MESSAGE_HASH: &str = "a268eead559ee12b6aff00a72a51a81d4a7007168f84e6780f750e02d7882b33";
const SIGNATURE_R: &str = "18751eeab194c5c52eccb9e3609f2a13ea98a079138dc29daf673911ae260899";
const SIGNATURE_S: &str = "73accbc38bab1964234ee0aead69389a79898c80bf8c3570633229ccf5f24a1e";

enum Transaction {
    CreateAccount = 1,
    HandleTransaction = 2,
}

impl Transaction {
    fn to_uint(&self) -> U256 {
        match self {
            Transaction::CreateAccount => U256::from(1),
            Transaction::HandleTransaction => U256::from(2),
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
        SendTransactionEvm { 
            destination_chain,
            destination_address,
            smart_account_address,
            recipient_address,
            amount,
        } => exec::send_transaction_evm(
                deps,
                env,
                info,
                destination_chain, 
                destination_address, 
                smart_account_address, 
                recipient_address,
                amount,
        ),
        SendTransactionEvmRaw { 
            destination_chain,
            destination_address,
            payload,
        } => exec::send_transaction_evm_raw(
                deps,
                env,
                info,
                destination_chain, 
                destination_address, 
                payload,
        ),
    }
}

mod exec {
    use cw_utils::one_coin;
    use neutron_sdk::{bindings::{msg::NeutronMsg, query::NeutronQuery, types::decode_hex}, query::min_ibc_fee::query_min_ibc_fee, sudo::msg::RequestPacketTimeoutHeight, NeutronResult};

    use super::*;

    pub fn create_account_evm(
        deps: DepsMut<NeutronQuery>,
        env: Env,
        info: MessageInfo,
        destination_chain: String,
        destination_address: String,
        owner: String,
    ) -> NeutronResult<Response<NeutronMsg>> {
        let message_hash_bytes = decode_hex(&MESSAGE_HASH).expect("Failed to decode message hash");
        let signature_r_bytes = decode_hex(&SIGNATURE_R).expect("Failed to decode signature r");
        let signature_s_bytes = decode_hex(&SIGNATURE_S).expect("Failed to decode signature s");

        // Message payload to be received by the destination
        let message_payload = encode(&vec![
            Token::Uint(Transaction::CreateAccount.to_uint()),
            Token::String(owner),
            Token::FixedBytes(message_hash_bytes),
            Token::FixedBytes(signature_r_bytes),
            Token::FixedBytes(signature_s_bytes),
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

    pub fn send_transaction_evm(
        deps: DepsMut<NeutronQuery>,
        env: Env,
        info: MessageInfo,
        destination_chain: String,
        destination_address: String,
        smart_account_address: String,
        recipient_address: String,
        amount: u64,
    ) -> NeutronResult<Response<NeutronMsg>> {
        let message_hash_bytes = decode_hex(&MESSAGE_HASH).expect("Failed to decode message hash");
        let signature_r_bytes = decode_hex(&SIGNATURE_R).expect("Failed to decode signature r");
        let signature_s_bytes = decode_hex(&SIGNATURE_S).expect("Failed to decode signature s");
        let data_bytes =  decode_hex("").expect("Failed to decode data");

        let amount_eth = U256::from(amount);

        // Message payload to be received by the destination
        let message_payload = encode(&vec![
            Token::Uint(Transaction::HandleTransaction.to_uint()),
            Token::String(smart_account_address),
            Token::FixedBytes(message_hash_bytes),
            Token::FixedBytes(signature_r_bytes),
            Token::FixedBytes(signature_s_bytes),
            Token::String(recipient_address),
            Token::Uint(amount_eth),
            Token::Bytes(data_bytes),
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

    pub fn send_transaction_evm_raw(
        deps: DepsMut<NeutronQuery>,
        env: Env,
        info: MessageInfo,
        destination_chain: String,
        destination_address: String,
        payload: String,
    ) -> NeutronResult<Response<NeutronMsg>> {
        // Message payload to be received by the destination
        let payload_bytes = decode_hex(&payload).expect("Failed to decode payload");

        // {info.funds} used to pay gas. Must only contain 1 token type.
        let coin: cosmwasm_std::Coin = one_coin(&info).unwrap();

        let fee: Option<Fee> = Some(Fee {
            amount: coin.amount.to_string(),
            recipient: AXELAR_FEE_RECIPIENT.to_string(),
        });

        let gmp_message: GmpMessage = GmpMessage {
            destination_chain,
            destination_address,
            payload: payload_bytes.to_vec(),
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