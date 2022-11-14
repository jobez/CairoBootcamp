%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_lt,
    uint256_eq,
    uint256_unsigned_div_rem,
    uint256_sub,
)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_nn,
    assert_le,
    assert_lt,
    assert_in_range,
)

from openzeppelin.access.ownable import Ownable
from openzeppelin.token.erc20.library import ERC20



@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, decimals: felt, initial_supply: Uint256, recipient: felt, owner: felt
) {

   with_attr error_message ("decimals must be zero per shamecoin spec") {
       assert decimals = 0;
   }

    
    ERC20.initializer(name, symbol, decimals);
    ERC20._mint(recipient, initial_supply);
    Ownable.initializer(owner);
    return ();
}

//
// Getters
//

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC20.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC20.symbol();
    return (symbol,);
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC20.total_supply();
    return (totalSupply,);
}

@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    let (decimals) = ERC20.decimals();
    return (decimals,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC20.balance_of(account);
    return (balance,);
}

@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, spender: felt
) -> (remaining: Uint256) {
    let (remaining: Uint256) = ERC20.allowance(owner, spender);
    return (remaining,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

func assert_one_shamecoin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(amount: Uint256) {

    let (one_shamecoin) = uint256_eq(amount, Uint256(1,0));

    with_attr error_message("can only transfer/approve spending of one shamecoin at a time") {
         assert one_shamecoin = 1;   
    }


    return ();
}

//
// Externals
//

@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
   alloc_locals;
   let (owner: felt) = Ownable.owner();
   let (caller : felt) = get_caller_address();


    assert_one_shamecoin(amount=amount);

    if (owner == caller) {
    // the administrator can send 1 shame coin at a time to other addresses (but keep the transfer function signature the same)
      tempvar syscall_ptr=syscall_ptr;
      tempvar pedersen_ptr=pedersen_ptr;
      tempvar range_check_ptr=range_check_ptr;
      ERC20.transfer(recipient, amount);
  
    } else {
    // if non administrators try to transfer their shame coin, the transfer funcion will instead increase their balance by one
      tempvar syscall_ptr=syscall_ptr;
      tempvar pedersen_ptr=pedersen_ptr;
      tempvar range_check_ptr=range_check_ptr;
      ERC20._mint(caller, amount);

    }

    
    return (TRUE,);
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    // the transfer from function should just reduce the balance of the holder
    let (caller) = get_caller_address();
     // subtract allowance
    ERC20._spend_allowance(sender, caller, amount);
    ERC20._burn(sender, amount);
    return (TRUE,);
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, amount: Uint256
) -> (success: felt) {
    // non administrators can approve the administrator (and only the administrator) to spend one token on their behalf
    alloc_locals;
    let (owner: felt) = Ownable.owner();
    let (caller : felt) = get_caller_address();
    with_attr error_message ("non administrators can only approve administrator to spend on their behalf") {
       assert spender = owner;
   }
    
    assert_one_shamecoin(amount=amount);
    let (remaining : Uint256) = ERC20.allowance(caller, owner);
    let (allowance_less_than_one) = uint256_lt(remaining, Uint256(1,0));
    
    with_attr error_message ("non administrators can only approve administrator to spend one shamecoin at a time") {
       assert allowance_less_than_one = 1;
   }

    ERC20.approve(spender, amount);
    return (TRUE,);
}

@external
func increaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, added_value: Uint256
) -> (success: felt) {
    ERC20.increase_allowance(spender, added_value);
    return (TRUE,);
}

@external
func decreaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, subtracted_value: Uint256
) -> (success: felt) {
    ERC20.decrease_allowance(spender, subtracted_value);
    return (TRUE,);
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, amount: Uint256
) {
    Ownable.assert_only_owner();
    ERC20._mint(to, amount);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}
