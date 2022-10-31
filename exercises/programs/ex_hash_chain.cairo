// Task:
// Develop a function that is going to calculate Pedersen hash of an array of felts.
// Cairo's built in hash2 can calculate Pedersen hash on two field elements.
// To calculate hash of an array use hash chain algorith where hash of [1, 2, 3, 4] is is H(H(H(1, 2), 3), 4).

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2


func get_pedersen{hash_ptr : HashBuiltin*}(s_seq_len : felt, d_seq: felt*, acc: felt) -> (res: felt) {
    alloc_locals;
    if (s_seq_len == 0) { 
        return (res=acc);
        
    }


    let seq_el : felt = [d_seq];

    let updated_acc : felt = hash2{hash_ptr=hash_ptr}(acc, seq_el);


    let recursed_acc : felt = get_pedersen(s_seq_len -1, d_seq+1, updated_acc);
    return (res=recursed_acc);
}

// Computes the Pedersen hash chain on an array of size `arr_len` starting from `arr_ptr`.
func hash_chain{hash_ptr: HashBuiltin*}(arr_ptr: felt*, arr_len: felt) -> (result: felt) {
    
    let first_element : felt = [arr_ptr];
    
    
    let pedersen_chain : felt = get_pedersen(arr_len-1, arr_ptr+1, first_element);

    
    return (result=pedersen_chain);
}
