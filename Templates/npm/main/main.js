$DEPENDENCY_IMPORTS

function dep_tree(indent) {
    const indent_str = "  ".repeat(indent);
    const my_name = "__main_pkg__";

    console.log(indent_str + my_name);
    $DEPENDENCY_TREE_CALLS
}

dep_tree(0);
