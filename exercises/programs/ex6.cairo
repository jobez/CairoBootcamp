from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

func recur_sum_even{bitwise_ptr: BitwiseBuiltin*}(idx : felt, array: felt* ,acc : felt) -> (final_acc: felt) {
    if (idx == 0) {
        return (final_acc=acc);
    }

    let element = [array];
    let is_odd : felt = bitwise_and(element, 1);
    if (is_odd == 1) {
       let res : felt = recur_sum_even(idx=idx-1, array=array+1, acc=acc);                
    } else {
       let res : felt = recur_sum_even(idx=idx-1, array=array+1, acc=acc+element);       
    }

    
    return (final_acc=res);

}

// Implement a function that sums even numbers from the provided array
func sum_even{bitwise_ptr: BitwiseBuiltin*}(arr_len: felt, arr: felt*, run: felt, idx: felt) -> (
    sum: felt
) {
    let summed : felt = recur_sum_even(idx=arr_len, array=arr, acc=0);
    
    return (sum=summed);
}
