$DEPENDENCY_IMPORTS

function dep_tree(indent) {
    const my_name = "__main_pkg__";

    console.log(indent + "," + my_name);
    $DEPENDENCY_TREE_CALLS
}

console.log("TREE DUMP:")
dep_tree(0);
