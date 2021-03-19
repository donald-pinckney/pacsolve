$DEPENDENCY_IMPORTS

function dep_tree(indent) {
    const my_name = "$NAME_STRING";
    const my_version = "$VERSION_STRING";
    
    console.log(indent + "," + my_name + " v" + my_version);
    $DEPENDENCY_TREE_CALLS
}

exports.dep_tree = dep_tree

