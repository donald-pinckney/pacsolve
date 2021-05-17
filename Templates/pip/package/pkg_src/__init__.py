from .__metadata__ import __version__, __name__

$DEPENDENCY_IMPORTS

COUNTER = 0

def inc_counter():
    global COUNTER
    ret = COUNTER
    COUNTER += 1
    return ret

def dep_tree(indent, do_inc):
    if do_inc:
        print("{},{} v{},#{}".format(indent, __name__, __version__, do_inc()))
    else:
        print("{},{} v{}".format(indent, __name__, __version__))
        
    $DEPENDENCY_TREE_CALLS
