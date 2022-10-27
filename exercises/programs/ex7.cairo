%lang starknet
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.pow import pow
from starkware.cairo.common.math import unsigned_div_rem

// Using binary operations return:
// - 1 when pattern of bits is 01010101 from LSB up to MSB 1, but accounts for trailing zeros
// - 0 otherwise

// 000000101010101 PASS
// 010101010101011 FAIL

func get_nth_bit{bitwise_ptr : BitwiseBuiltin*, range_check_ptr : felt}(value, n) -> felt {
   let (pow2n) = pow(2, n);
   let (and_val) = bitwise_and(value, pow2n);
   let res = is_not_zero(and_val);
   return (res);
}

func jhnn_pattern{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(value : felt, idx: felt, last_bit: felt, zero_trail : felt) -> (true: felt) {

    let bit : felt = get_nth_bit(value, idx);
     %{
    print(f"{ids.idx=} {ids.last_bit=} {ids.zero_trail=} {ids.bit=}")
    %}

    if (zero_trail == 1) {
        if (bit == 0) {
           let succ : felt = jhnn_pattern(value=value, idx=idx-1, last_bit=bit, zero_trail=1); 
           return (true=succ); 
        } else {
           let succ : felt = jhnn_pattern(value=value, idx=idx-1, last_bit=bit, zero_trail=0); 
           return (true=succ); 
        }

    } else {
        let zero_one_pair = last_bit + bit;    
        if (zero_one_pair == 1) {
           if (idx == 0) { 
             return (true=1);   
           } else { 

            let succ : felt = jhnn_pattern(value=value, idx=idx-1, last_bit=bit, zero_trail=0); 
            return (true=succ); 
          } 
        } else {
            
           return (true=0); 
        }
    

    }
    

}

func pattern{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    n: felt, idx: felt, exp: felt, broken_chain: felt
) -> (true: felt) {
    
    
    let res : felt = jhnn_pattern(value=n, idx=15, last_bit=0, zero_trail=1);
    
    return (true=res);
}
