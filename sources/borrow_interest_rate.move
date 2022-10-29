module lend_config::borrow_interest_rate{

    use std::signer;
    use std::error;
    use lend_config::math;
    use aptos_std::type_info::{TypeInfo, type_of};
    use std::vector;
    use lend_config::math::sqrt;

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
        // assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));
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
        // assert!(account_addr == @lend_config, error::permission_denied(ENOT_ALLOWED));

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
                c: 8000,
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

    // result extend 100000 times
    public fun calc_borrow_interest_rate<C>(u: u64): u64 acquires Params {

        let params = borrow_global<Params>(@lend_config);

        let type_info = type_of<C>();
        let (e, i) = contains(&params.vals, &type_info);
        if (e) {
            let formula = vector::borrow(&params.vals, i);
            // u extend 1000 times
            if (u < 8000) {
                // y = kx + b
                (formula.k * u + 10 * formula.b) / 10
            } else {
                // y = a (u - c)^3/2 + d
                (formula.a * (u - formula.c) * sqrt(((u - formula.c) as u128)) + 10 * formula.d) / 10
            }
        } else {
            abort ENOT_FOUND_FORMULA
        }
    }

    // result extend 100 times
    public fun calc_borrow_interest_rate_with_diff_time<C>(u: u64, diff_time: u64): u64 acquires Params {
        calc_borrow_interest_rate<C>(u) * diff_time
    }

    public fun calc_borrow_interest_rate_with_diff_time_u128<C>(u: u64, diff_time: u64): u128 acquires Params {
        (calc_borrow_interest_rate<C>(u) as u128) * (diff_time as u128)
    }

    // result extend 100000 times, should div 100000  todo: remove generic
    public fun calc_supply_interest_rate<C>(borrow_interest_rate: u64, u: u64): u64 {
        math::mul_div(borrow_interest_rate, u, 10000)
    }

    // result extend 100000 times, should div 100000
    public fun calc_supply_interest_rate_with_diff_time(borrow_interest_rate: u64, u: u64, diff_time: u64): u64 {
        math::mul_div(borrow_interest_rate * diff_time, u, 10000)
    }

    public fun calc_supply_interest_rate_with_diff_time_u128(borrow_interest_rate: u64, u: u64, diff_time: u64): u128 {
        (borrow_interest_rate as u128) * (diff_time as u128) * (u as u128) / (10000 as u128)
    }

    // result extend 10000 times
    public fun calc_utilization<C>(borrow: u128, supply: u128): u64 {
        if (supply == 0) {
            supply = 1
        };
        math::mul_div_u128(borrow, 10000, supply)
    }

    /// Return index, the result is extended 10000 times
    public fun calc_index<C>(old_index: u64, interest_rate: u64): u64 {
        (old_index * (100000 + interest_rate) + 50000) / 100000
    }

    public fun calc_index_u128<C>(old_index: u64, interest_rate: u64): u128 {
        ((old_index as u128) * (100000 + interest_rate as u128) + 50000) / 100000
    }

    public fun calc_index_u128_u128<C>(old_index: u64, interest_rate: u128): u128 {
        ((old_index as u128) * (100000 + interest_rate) + 50000) / 100000
    }

    /// Return index, the result is extended 100 times
    public fun calc_index2(old_index: u64, interest_rate: u64): u64 {
        old_index * (100 + interest_rate) / 100
    }

    #[test_only]
    struct FMK {}

    #[test_only]
    use aptos_std::debug::print;



    #[test_only(alice=@0x01)]
    fun calc_rate<C>(alice: &signer, u: u64): u64 acquires Params {
        let params = borrow_global<Params>(signer::address_of(alice));

        let formula = vector::borrow(&params.vals, 0);

        let r = if (u < 8000) {
            // y = kx + b
            (formula.k * u + 10 * formula.b) / 10
        } else {
            // y = a (u - c)^2 + d
            (formula.a * (u - formula.c) * sqrt(((u - formula.c) as u128)) + 10 * formula.d) / 10
        };
        print(&r);
        r
    }

    #[test(alice=@0x01)]
    fun test_calc_borrow_interest_rate(alice: &signer) acquires Params {
        initialize(alice);

        add<FMK>(alice, 20, 1000, 20, 12930);

        assert!(calc_rate<FMK>(alice, 0) == 1000, 1);
        assert!(calc_rate<FMK>(alice, 950) == 2900, 1);

        let diff_time = 100;
        assert!(calc_rate<FMK>(alice, 950) * diff_time, 1);
    //     assert!(calc_rate<FMK>(alice, 100) == 2660, 1);
    //     assert!(calc_rate<FMK>(alice, 1000) == 3830, 1);
    //     assert!(calc_rate<FMK>(alice, 2000) == 5130, 1);
    //     assert!(calc_rate<FMK>(alice, 3000) == 6430, 1);
    //     assert!(calc_rate<FMK>(alice, 4000) == 7730, 1);
    //     assert!(calc_rate<FMK>(alice, 5000) == 9030, 1);
    //     assert!(calc_rate<FMK>(alice, 6000) == 10330, 1);
    //     assert!(calc_rate<FMK>(alice, 7000) == 11630, 1);
    //     assert!(calc_rate<FMK>(alice, 7999) == 12928, 1);
    //
    //     assert!(calc_rate<FMK>(alice, 8000) == 12930, 1);
    //     assert!(calc_rate<FMK>(alice, 8020) == 13090, 1);
    //     assert!(calc_rate<FMK>(alice, 8153) == 16602, 1);
    //     assert!(calc_rate<FMK>(alice, 8510) == 35370, 1);
    //     assert!(calc_rate<FMK>(alice, 9000) == 74930, 1);
    //     assert!(calc_rate<FMK>(alice, 9500) == 126930, 1);
    //     assert!(calc_rate<FMK>(alice, 10000) == 188930, 1);
    }

    #[test]
    fun test_calc_index_u128_u128() {

        let i = calc_index_u128_u128<FMK>(10000, 139200);
        print(&i);
        assert!(i == 23920, 1);
    }

    // #[test(bob=@0x02)]
    // fun test_calc_supply_interest_rate(bob: &signer) acquires Params {
    //     initialize(bob);
    //
    //     add<FMK>(bob, 20, 1000, 20, 12930);
    //
    //     let u = 0;
    //     let r = calc_rate<FMK>(bob, u);
    //     let sr = calc_supply_interest_rate<FMK>(r, u);
    //     let i = calc_index<FMK>(10000, r);
    //     print(&i);
    //
    //     assert!(sr == 0, 2);
    //     assert!(i == 10100, 2);
    //
    //     let u = 10;
    //     let r = calc_rate<FMK>(bob, u);
    //     let sr = calc_supply_interest_rate<FMK>(r, u);
    //     let i = calc_index<FMK>(10253, r);
    //     print(&i);
    //
    //     assert!(sr == 2543, 2);
    //     assert!(i == 10513, 2);

        // let u = 100;
        // let r = calc_rate<FMK>(bob, u);
        // let sr = calc_supply_interest_rate<FMK>(r, u);
        // let i = calc_index<FMK>(10792, r);
        // print(&i);
        //
        // assert!(sr == 26600, 2);
        // assert!(i == 11079, 2);
        //
        // let u = 1000;
        // let r = calc_rate<FMK>(bob, u);
        // let sr = calc_supply_interest_rate<FMK>(r, u);
        // let i = calc_index<FMK>(11079, r);
        // print(&sr);
        // print(&i);
        //
        // assert!(sr == 383000, 2);
        // assert!(i == 11503, 2);
        //
        // let u = 5000;
        // let r = calc_rate<FMK>(bob, u);
        // let sr = calc_supply_interest_rate<FMK>(r, u);
        // let i = calc_index<FMK>(11503, r);
        // print(&sr);
        // print(&i);
        //
        // assert!(sr == 4515000, 2);
        // assert!(i == 12541, 2);
        //
        // let u = 8000;
        // let r = calc_rate<FMK>(bob, u);
        // let sr = calc_supply_interest_rate<FMK>(r, u);
        // let i = calc_index<FMK>(12541, r);
        // print(&sr);
        // print(&i);
        //
        // assert!(sr == 10344000, 2);
        // assert!(i == 14162, 2);
    // }


}