module lend_config::borrow_interest_rate{

    use std::signer;
    use std::error;
    use lend_config::math;
    use aptos_std::type_info::{TypeInfo, type_of};
    use std::vector;

    const EALREADY_PUBLISHED_FORMULAPARAM: u64 = 1;
    const ENOT_PUBLISHED_FORMULAPARAM: u64 = 2;
    const ENOT_ALLOWED: u64 = 3;
    const EALREADY_ADDED: u64 = 4;
    const ENOT_FOUND_FORMULA: u64 = 5;

    struct FormulaParam has copy, drop, store {
        ct: TypeInfo,
        k: u64,   // interest rate growth factor, extend 100 times
        b: u64,  // base rate, extend 1000 times

        a: u64,   // interest rate growth factor
        c: u64,   // offset u, extend 1000 times
        d: u64,   // offset y, extend 100 times
        // todo: reserves
        reserves: u64  // reserves, extend 1000 times
    }

    struct Params has key, store {
        vals: vector<FormulaParam>
    }


    public entry fun initialize(account: &signer, ) {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
        assert!(!exists<Params>(account_addr), EALREADY_PUBLISHED_FORMULAPARAM);

        move_to(account, Params {
            vals: vector::empty()
        })
    }

    fun contains(params: &vector<FormulaParam>, ct: &TypeInfo): (bool, u64) {
        let len = vector::length(params);
        let i = 0;
        while (i < len) {
            let param = vector::borrow(params, i);
            if (param.ct == *ct) {
                return (true, i)
            };
            i = i + 1
        };
        (false, 0)
    }

    public entry fun add<C>(account: &signer, k: u64, b: u64, a: u64, d: u64) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));

        let params = borrow_global_mut<Params>(account_addr);

        let type_info = type_of<C>();

        let (e, _i) = contains(&params.vals, &type_info);

        if (e) {
            abort EALREADY_ADDED
        } else {
            vector::push_back(&mut params.vals, FormulaParam {
                ct: type_info,
                k,
                b,

                a,
                c: 800,
                d,
                reserves: 0
            })
        }

    }

    public entry fun set_k<C>(account: &signer, k: u64) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
        assert!(exists<Params>(account_addr), ENOT_PUBLISHED_FORMULAPARAM);

        let params = borrow_global_mut<Params>(account_addr);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.k = k
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }


    public entry fun set_b<C>(account: &signer, b: u64) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
        assert!(exists<Params>(account_addr), ENOT_PUBLISHED_FORMULAPARAM);

        let params = borrow_global_mut<Params>(account_addr);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.b = b
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_a<C>(account: &signer, a: u64) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
        assert!(exists<Params>(account_addr), ENOT_PUBLISHED_FORMULAPARAM);

        let params = borrow_global_mut<Params>(account_addr);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.a = a
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_c<C>(account: &signer, c: u64) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
        assert!(exists<Params>(account_addr), ENOT_PUBLISHED_FORMULAPARAM);

        let params = borrow_global_mut<Params>(account_addr);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.c = c
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_d<C>(account: &signer, d: u64) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
        assert!(exists<Params>(account_addr), ENOT_PUBLISHED_FORMULAPARAM);

        let params = borrow_global_mut<Params>(account_addr);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.d = d
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    public entry fun set_reserves<C>(account: &signer, reserves: u64) acquires Params {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
        assert!(exists<Params>(account_addr), ENOT_PUBLISHED_FORMULAPARAM);

        let params = borrow_global_mut<Params>(account_addr);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow_mut(&mut params.vals, i);
            formula.reserves = reserves
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    // result extend 100 times
    public fun calc_borrow_interest_rate<C>(u: u64): u64 acquires Params {
        let params = borrow_global<Params>(@lend_config);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow(&params.vals, i);
            // u extend 1000 times
            if (u < 8000) {
                // y = kx + b
                (formula.k * u + formula.b * 100) / 1000
            } else {
                // y = a (u - c)^2 + d
                (formula.a * (u - formula.c) * (u - formula.c) + 1000 * formula.d) / 10000
            }
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    // result extend 100 times
    public fun calc_borrow_interest_rate_with_diff_time<C>(u: u64, diff_time: u64): u64 acquires Params {
        calc_borrow_interest_rate<C>(u) * diff_time
    }

    // result extend 100 times  todo: remove generic
    public fun calc_supply_interest_rate<C>(borrow_interest_rate: u64, u: u64): u64 {
        math::mul_div(borrow_interest_rate, u, 1000)
    }

    // result extend 100 times
    public fun calc_supply_interest_rate_with_diff_time(borrow_interest_rate: u64, u: u64, diff_time: u64): u64 {
        math::mul_div(borrow_interest_rate * diff_time, u, 1000)
    }

    // result extend 1000 times
    public fun calc_utilization<C>(borrow: u128, supply: u128): u64 {
        math::mul_div_u128(borrow, 1000, supply)
    }

    /// Return index, the result is extended 100 times
    public fun calc_index<C>(old_index: u64, interest_rate: u64): u64 {
        old_index * (100 + interest_rate) / 100
    }

    /// Return index, the result is extended 100 times
    public fun calc_index2(old_index: u64, interest_rate: u64): u64 {
        old_index * (100 + interest_rate) / 100
    }

}