$DEPENDENCY_IMPORTS

//var COUNTER = 0;
//
//function inc_counter() {
//    const ret = COUNTER;
//    COUNTER += 1;
//    return ret;
//}

function dep_tree(indent) {
    const my_name = "$NAME_STRING";
    const my_version = "$VERSION_STRING";
    
    console.log(indent + "," + my_name + " v" + my_version);
    $DEPENDENCY_TREE_CALLS
}

exports.dep_tree = dep_tree

if (require.main === module) {
    console.log("TREE DUMP:")
    dep_tree(0);
}
