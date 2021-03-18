$DEPENDENCY_IMPORTS

fn dep_tree(indent: usize) {
    let indent_str = "  ".repeat(indent);
    println!("{}{} v{}", indent_str, "$NAME_STRING", "$VERSION_STRING");
    
    $DEPENDENCY_TREE_CALLS
}

fn main() {
    println!("TREE DUMP:");
    dep_tree(0);
}
