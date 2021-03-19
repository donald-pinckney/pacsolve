from .__metadata__ import __version__, __name__

$DEPENDENCY_IMPORTS

def dep_tree(indent):
    print("{},{} v{}".format(indent, __name__, __version__))
    
    $DEPENDENCY_TREE_CALLS
