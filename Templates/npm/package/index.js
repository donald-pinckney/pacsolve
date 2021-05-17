$DEPENDENCY_IMPORTS

var COUNTER = 0;

function inc_counter() {
    const ret = COUNTER;
    COUNTER += 1;
    return ret;
}

function dep_tree(indent, do_inc) {
    const my_name = "$NAME_STRING";
    const my_version = "$VERSION_STRING";
    
    if(do_inc) {
        console.log(indent + "," + my_name + "," + my_version + "," + inc_counter());
    } else {
        console.log(indent + "," + my_name + "," + my_version);
    }
    $DEPENDENCY_TREE_CALLS
}

exports.dep_tree = dep_tree
exports.inc_counter = inc_counter

if (require.main === module) {
    console.log("TREE DUMP:")
    dep_tree(0, true);
}
