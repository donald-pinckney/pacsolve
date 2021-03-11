$DEPENDENCY_IMPORTS

def dep_tree(indent):
    indent_str = "  "
    print((indent * indent_str) + "__main_pkg__")
    
    $DEPENDENCY_TREE_CALLS

def main():
    dep_tree(0)
    
if __name__ == "__main__":
    main()
