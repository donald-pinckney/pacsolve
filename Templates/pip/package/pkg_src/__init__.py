from .__metadata__ import __version__, __name__

$DEPENDENCY_IMPORTS

def dep_tree(indent):
    indent_str = "  "
    print((indent * indent_str) + __name__ + " v" + __version__)
    
    $DEPENDENCY_TREE_CALLS
