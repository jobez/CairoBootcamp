%lang starknet

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_eq,
    uint256_unsigned_div_rem,
    uint256_sub,
)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin


const MINT_ADMIN = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a91;
const TEST_ACC1 = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a95;
const TEST_ACC2 = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b;

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20 as ERC20

@external
func __setup__() {
    // Deploy contract
    %{
        context.contract_a_address  = deploy_contract("./exercises/contracts/erc20/shamecoin.cairo", [
                2128896981611511245166, ## name:   shamecoin
               21315,                           ## symbol: SC
                0,                              ## zero decimals
               10000000000,                     ## initial_supply[1]: 10000000000
               0,                               ## initial_supply[0]: 0
               ids.MINT_ADMIN,                  ## recipient
               ids.MINT_ADMIN                   ## owner
               ]).contract_address
    %}
    return ();
}

@external
func test_name_is_shamecoin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as admin
    %{ stop_prank_callable = start_prank(ids.MINT_ADMIN, ids.contract_address) %}

    let (name) = ERC20.name(contract_address=contract_address);

    assert name = 'shamecoin';
    return ();
}

@external
func test_decimals_is_zero{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}


    // Get airdrop under limit
    let (decimals) = ERC20.decimals(contract_address=contract_address);

    assert decimals = 0;


    return ();
}

@external
func test_send_only_one_shamecoin_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // admin can send/mint shamecoin, but only one at a time.
    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}



    // Call as admin
    %{ stop_prank_callable = start_prank(ids.MINT_ADMIN, ids.contract_address) %}

    // // admin should be able to send one shamecoin at a time
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC1, amount=Uint256(1, 0));



    let (recipient_balance) = ERC20.balanceOf(
         contract_address=contract_address, account=TEST_ACC1
    );

    let (balance_is_one) = uint256_eq(recipient_balance, Uint256(1, 0));
    
    assert balance_is_one = 1;

    tempvar contract_address2;
    %{ ids.contract_address2 = context.contract_a_address %}

    // but only one shamecoin
    %{ expect_revert() %}
    ERC20.transfer(contract_address=contract_address2, recipient=TEST_ACC1, amount=Uint256(2, 0));


    %{ stop_prank_callable() %}
    return ();
}


@external
func test_send_only_one_shamecoin_nonadmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // nonadmins should receive error when they try to transfer more than one shamecoin.
    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as non-admin
     %{ stop_prank_callable = start_prank(ids.TEST_ACC1, ids.contract_address) %}
    // nonadmins get shamed when trying to transfer shame
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));

     let (recipient_balance) = ERC20.balanceOf(
         contract_address=contract_address, account=TEST_ACC1
    );

    let (balance_is_one) = uint256_eq(recipient_balance, Uint256(1, 0));
    
    assert balance_is_one = 1;

    // and are still held to the `only one` restriction
    tempvar contract_address2;
    %{ ids.contract_address2 = context.contract_a_address %}
    %{ expect_revert() %}
     ERC20.transfer(contract_address=contract_address2, recipient=TEST_ACC1, amount=Uint256(2, 0));
    %{ stop_prank_callable() %}

    
    return ();

}

@external
func test_approve_limit_to_only_one_at_a_time{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // attempting to approve with an amount greater than 1 should error
    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as non-admin
     %{ stop_prank_callable = start_prank(ids.TEST_ACC1, ids.contract_address) %}
    // build up shame balance
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));
    
    // non admin cannot approve more than 1 shamecoin at a time
    %{ expect_revert() %}
    ERC20.approve(contract_address=contract_address, spender=MINT_ADMIN, amount=Uint256(2, 0));

    %{ stop_prank_callable() %}


    return ();
}

@external
func test_approve_limit_to_only_one{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // two separate approvals to admin where the admin hasn't spent yet should throw error
    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as non-admin
     %{ stop_prank_callable = start_prank(ids.TEST_ACC1, ids.contract_address) %}
    // build up shame balance
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));
    
     ERC20.approve(contract_address=contract_address, spender=MINT_ADMIN, amount=Uint256(1, 0));
    // non admin cannot approve more than 1 shamecoin at a time
    %{ expect_revert() %}
    // so we cannot approve one more shame coin until the previous approval is spent
    ERC20.approve(contract_address=contract_address, spender=MINT_ADMIN, amount=Uint256(1, 0));

    %{ stop_prank_callable() %}


    return ();
}

@external
func test_approve_nonadmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    // only admin can be approved for an allowance
    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as non-admin
     %{ stop_prank_callable = start_prank(ids.TEST_ACC1, ids.contract_address) %}
    // build up shame balance
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));
    

    // non admin cannot approve more than 1 shamecoin at a time
    %{ expect_revert() %}
    // so we cannot approve one more shame coin until the previous approval is spent
    ERC20.approve(contract_address=contract_address, spender=TEST_ACC2, amount=Uint256(1, 0));

    %{ stop_prank_callable() %}


    return ();
}


@external
func test_approval_and_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // the transfer from function should just reduce the balance of the holder   
    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as non-admin
     %{ stop_prank_callable = start_prank(ids.TEST_ACC1, ids.contract_address) %}
    // build up shame balance
    ERC20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));

    ERC20.approve(contract_address=contract_address, spender=MINT_ADMIN, amount=Uint256(1, 0));

    %{ stop_prank_callable() %}

    tempvar contract_address2;
    %{ ids.contract_address2 = context.contract_a_address %}

   %{ stop_prank_callable = start_prank(ids.MINT_ADMIN, ids.contract_address2) %}

     ERC20.transferFrom(contract_address=contract_address, sender=TEST_ACC1, recipient=TEST_ACC2, amount=Uint256(1, 0));

     let (recipient_balance) = ERC20.balanceOf(
         contract_address=contract_address, account=TEST_ACC1
    );

    let (balance_is_zero) = uint256_eq(recipient_balance, Uint256(0, 0));
    
    assert balance_is_zero = 1;

    %{ stop_prank_callable() %}

    return ();


}


