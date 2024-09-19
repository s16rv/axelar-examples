use ethabi::{encode, ethereum_types::U256, Token};
use neutron_sdk::{bindings::types::{decode_hex, encode_hex}, proto_types::neutron::interchainqueries::TxValue};

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

#[test]
fn query_admin() {
    const TX_PAYLOAD: &str = "3f579f42000000000000000000000000390dc2368bfde7e7a370af46c0b834b718d570c100000000000000000000000000000000000000000000000000038d7ea4c6800000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000";
    const SMART_ACCOUNT_ADDRESS: &str = "0x63d9e7007B0d27628bAFf15137F2ECef3176b991";

    let tx_payload_bytes = decode_hex(TX_PAYLOAD).expect("Failed to decode tx payload");
    assert_eq!(
        encode_hex(&tx_payload_bytes),
        TX_PAYLOAD,
    );

    let message_payload = encode(&vec![
        Token::Uint(Transaction::HandleTransaction.to_uint()),
        Token::String(SMART_ACCOUNT_ADDRESS.to_string()),
        Token::FixedBytes(tx_payload_bytes),
    ]);

    assert_eq!(
        encode_hex(&message_payload),
        TX_PAYLOAD,
    );

    // assert_eq!(
    //     encode_hex(&message_payload),
    //     "0x000000000000000000000000000000000000000000000000000000000000000200000000000000000000000094099942864ea81ccf197e9d71ac53310b1468d8000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000843f579f4200000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c800000000000000000000000000000000000000000000000000038d7ea4c680000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    // )
}

#[test]
fn decode_hash() {
    const MESSAGE_HASH: &str = "a268eead559ee12b6aff00a72a51a81d4a7007168f84e6780f750e02d7882b33";
    const SIGNATURE_R: &str = "18751eeab194c5c52eccb9e3609f2a13ea98a079138dc29daf673911ae260899";
    const SIGNATURE_S: &str = "73accbc38bab1964234ee0aead69389a79898c80bf8c3570633229ccf5f24a1e";

    let message_hash_bytes = decode_hex(&MESSAGE_HASH).expect("Failed to decode message hash");
    let signature_r_bytes = decode_hex(&SIGNATURE_R).expect("Failed to decode signature r");
    let signature_s_bytes = decode_hex(&SIGNATURE_S).expect("Failed to decode signature s");
    let data_bytes =  decode_hex("").expect("Failed to decode data");
}