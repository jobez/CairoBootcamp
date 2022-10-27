from starkware.cairo.common.math import abs_value

// Implement a funcion that returns:
// - 1 when magnitudes of inputs are equal
// - 0 otherwise
func abs_eq{range_check_ptr}(x: felt, y: felt) -> (bit: felt) {
    tempvar abs_x = abs_value(x);
    tempvar abs_y = abs_value(y);
    
    if (abs_x == abs_y) {
       return (bit=1);
    } else {
       return (bit=0);
    }

}
