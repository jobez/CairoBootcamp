%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt, assert_le, assert_nn
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow
from starkware.cairo.common.hash_state import hash_init, hash_update
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from lib.constants import TRUE, FALSE

// Structs
//#########################################################################################

struct Consortium {
    chairperson: felt,
    proposal_count: felt,
}

struct Member {
    votes: felt,
    prop: felt,
    ans: felt,
}

struct Answer {
    text: felt,
    votes: felt,
}

struct Proposal {
    type: felt,  // whether new answers can be added
    win_idx: felt,  // index of preffered option
    ans_idx: felt,
    deadline: felt,
    over: felt,
}

// remove in the final asnwerless
struct Winner {
    highest: felt,
    idx: felt,
}

// Storage
//#########################################################################################

@storage_var
func consortium_idx() -> (idx: felt) {
}

@storage_var
func consortiums(consortium_idx: felt) -> (consortium: Consortium) {
}

@storage_var
func members(consortium_idx: felt, member_addr: felt) -> (memb: Member) {
}

@storage_var
func proposals(consortium_idx: felt, proposal_idx: felt) -> (win_idx: Proposal) {
}

@storage_var
func proposals_idx(consortium_idx: felt) -> (idx: felt) {
}

@storage_var
func proposals_title(consortium_idx: felt, proposal_idx: felt, string_idx: felt) -> (
    substring: felt
) {
}

@storage_var
func proposals_link(consortium_idx: felt, proposal_idx: felt, string_idx: felt) -> (
    substring: felt
) {
}

@storage_var
func proposals_answers(consortium_idx: felt, proposal_idx: felt, answer_idx: felt) -> (
    answers: Answer
) {
}

@storage_var
func voted(consortium_idx: felt, proposal_idx: felt, member_addr: felt) -> (true: felt) {
}

@storage_var
func answered(consortium_idx: felt, proposal_idx: felt, member_addr: felt) -> (true: felt) {
}

// External functions
//#########################################################################################

@external
func create_consortium{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let consortium_id : felt = consortium_idx.read();
    consortium_idx.write(consortium_id + 1);
    //caller as chairperson
    let consortium = Consortium(chairperson=caller, proposal_count=0);
    consortiums.write(consortium_id, consortium);
    // chairperson is a member with 100 votes and ability to add proposal and answers

    add_member(consortium_idx=consortium_id, member_addr=caller, prop=1 , ans=1, votes=100);


    return ();
}

func write_answers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(consortium_idx: felt, proposal_idx : felt, answers : felt*, answer_idx : felt, setter_idx : felt, offset : felt) {
    if (setter_idx == answer_idx) {
       return (); 
    }
    
    let answer_text : felt = [answers];
    let answer : Answer = Answer(text=answer_text, votes=0);
    let offset_idx : felt = setter_idx + offset;
    proposals_answers.write(consortium_idx, proposal_idx, offset_idx, answer);
   //  %{
   //  print(f" {ids.offset=} {ids.offset_idx=} {ids.answer_text=}  {ids.setter_idx=} ")
   // %}
    write_answers(consortium_idx, proposal_idx, answers+1, answer_idx, setter_idx+1, offset);
    return ();
}

func write_title{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(consortium_idx: felt, proposal_idx : felt, title_elements : felt*, title_idx : felt) {
    if (title_idx == 0) {
       return (); 
    }
    
    let title_el : felt = [title_elements];


    proposals_title.write(consortium_idx, proposal_idx, title_idx-1, title_el);

    write_title(consortium_idx, proposal_idx, title_elements+1, title_idx-1);
    return ();
}

@external
func add_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt,
    title_len: felt,
    title: felt*,
    link_len: felt,
    link: felt*,
    ans_len: felt,
    ans: felt*,
    type: felt,
    deadline: felt,
) {
    alloc_locals;
    let proposal_id : felt = proposals_idx.read(consortium_idx);

    write_title(consortium_idx, proposal_id, title, title_len);
    write_answers(consortium_idx, proposal_id, ans, ans_len, 0, 0);
    let proposal : Proposal = Proposal(type=type, win_idx=0, ans_idx=ans_len, deadline=deadline, over=0);
    proposals.write(consortium_idx, proposal_id, proposal);    

    proposals_idx.write(consortium_idx, proposal_id + 1);
    return ();
}

@external
func add_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, member_addr: felt, prop: felt, ans: felt, votes: felt
) {

    let (caller) = get_caller_address();

    let consortium : Consortium = consortiums.read(consortium_idx);

    assert consortium.chairperson = caller;

    let member : Member = Member(votes=votes, prop=prop, ans=ans);
    
    members.write(consortium_idx=consortium_idx, member_addr=member_addr, value=member);

    return ();
}

@external
func add_answer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, string_len: felt, string: felt*
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let proposal : Proposal = proposals.read(consortium_idx, proposal_idx);
    write_answers(consortium_idx, proposal_idx, string, string_len, 0, proposal.ans_idx);
    let updated_proposal : Proposal = Proposal(proposal.type, proposal.win_idx, proposal.ans_idx+string_len, proposal.deadline, proposal.over);
    proposals.write(consortium_idx, proposal_idx, updated_proposal);
    answered.write(consortium_idx, proposal_idx, caller, 1);
    return ();
}

@external
func vote_answer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, answer_idx: felt
) {
    // TODO: do i need to check if a person can/has enough votes?
    let (caller) = get_caller_address();
    let answer : Answer = proposals_answers.read(consortium_idx, proposal_idx, answer_idx);
    let has_voted : felt = voted.read(consortium_idx, proposal_idx, caller);
    assert has_voted = 0;
    
    let member : Member = members.read(consortium_idx, caller);

    let voted_answer = Answer(answer.text, answer.votes+member.votes);
    proposals_answers.write(consortium_idx, proposal_idx, answer_idx, voted_answer);

    voted.write(consortium_idx, proposal_idx, caller, 1);
    
    return ();
}

@external
func tally{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt
) -> (win_idx: felt) {
    let proposal : Proposal = proposals.read(consortium_idx, proposal_idx);
    let answer_index = proposal.ans_idx;
   
    let winner_idx : felt = find_highest(consortium_idx=consortium_idx, proposal_idx=proposal_idx, highest=0, idx=answer_index,  countdown=0);
     %{
    print(f"from tally we get {ids.winner_idx=} ")
    %}
    return (winner_idx,);
}


// Internal functions
//#########################################################################################


func find_highest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, highest: felt, idx: felt, countdown: felt
) -> (idx: felt) {

    if (idx == 0) {
    %{
    print(f"we finally return {ids.highest=} ")
    %}
      return (idx=highest);  
    }

    let answer : Answer = proposals_answers.read(consortium_idx, proposal_idx, idx-1);
    let answer_votes : felt = answer.votes;
    let current_answer_is_highest = is_le(countdown, answer_votes);
    %{
    print(f"{ids.idx=} {ids.answer_votes=} {ids.current_answer_is_highest=} {ids.countdown=} ")
    %}
    if (current_answer_is_highest == 1) {
    
     let res : felt = find_highest(consortium_idx=consortium_idx, proposal_idx=proposal_idx, highest=idx-1, idx=idx-1, countdown=answer_votes);
    } else {

     let res : felt = find_highest(consortium_idx=consortium_idx, proposal_idx=proposal_idx, highest=highest, idx=idx-1, countdown=countdown);


    }


    return (idx=res);    
}

// Loads it based on length, internall calls only
func load_selector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    string_len: felt,
    string: felt*,
    slot_idx: felt,
    proposal_idx: felt,
    consortium_idx: felt,
    selector: felt,
    offset: felt,
) {

    return ();
}
