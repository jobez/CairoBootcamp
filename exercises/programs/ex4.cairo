func recur_calculate_sum(idx : felt, acc : felt) -> (final_acc: felt) {
    if (idx == 0) {
        return (final_acc=acc);
    }

    let res : felt = recur_calculate_sum(idx=idx-1, acc=acc+idx);
    return (final_acc= res);

}

// Return summation of every number below and up to including n
func calculate_sum(n: felt) -> (sum: felt) {
    let res_sum : felt = recur_calculate_sum(idx=n, acc=0);
    return (sum= res_sum);
}
