use crate::utils::{Symbol, TokenAmount, VecOrSingle};
use minicbor::{Decode, Encode};
use omni::Identity;
use std::collections::BTreeMap;

#[derive(Encode, Decode)]
#[cbor(map)]
pub struct BalanceArgs {
    #[n(0)]
    pub account: Option<Identity>,

    #[n(1)]
    pub symbols: Option<VecOrSingle<Symbol>>,
}

#[derive(Encode, Decode)]
#[cbor(map)]
pub struct BalanceReturns {
    #[n(0)]
    pub balances: BTreeMap<Symbol, TokenAmount>,
}
