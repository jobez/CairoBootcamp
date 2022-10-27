from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem

// Perform and log output of simple arithmetic operations
func simple_math{range_check_ptr}() {
   // adding 13 +  14
    let first_add = 13 + 14;



   // multiplying 3 * 6
   let first_mult = 3 * 6;

   // dividing 6 by 2

   let first_divide = 6 / 2;

   // dividing 70 by 2

   let second_divide = 70 / 2;

   // dividing 7 by 2
   let seven = Uint256(7, 0);
   let two = Uint256(2, 0);

   let (third_quotient, third_remainder) = uint256_unsigned_div_rem(seven, two);

    %{
    print(f"{ids.first_add=} {ids.first_mult=} {ids.first_divide=} {ids.second_divide=} {ids.third_quotient.low=} {ids.third_quotient.high=} {ids.third_remainder.low=} {ids.third_remainder.high=}")
   %}

    return ();
}
