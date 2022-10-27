from starkware.cairo.common.uint256 import Uint256, uint256_add

// Modify both functions so that they increment
// supplied value and return it
func add_one(y: felt) -> (val: felt) {
    return (y+1,);
}

func add_one_U256{range_check_ptr}(y: Uint256) -> (val: Uint256) {
    let (added, _) = uint256_add(y, Uint256(1,0));
   %{
    print(f"{ids.added.low=} {ids.added.high=} {ids.y.low=}")
   %}
    return (added,);
}
