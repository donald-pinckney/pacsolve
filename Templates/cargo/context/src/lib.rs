static mut COUNTER: u32 = 0;

fn inc_counter() -> u32 {
    unsafe {
        let ret = COUNTER;
        COUNTER += 1;
        ret
    }
}

pub fn dep_tree(indent: usize, do_inc: bool) {
    if do_inc {
        println!("{},{},{},{}", indent, "$NAME_STRING", "$VERSION_STRING", inc_counter());
    } else {
        println!("{},{},{}", indent, "$NAME_STRING", "$VERSION_STRING");
    }
    
    $DEPENDENCY_TREE_CALLS
}
