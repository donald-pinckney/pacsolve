$DEPENDENCY_IMPORTS

def dep_tree(indent):
    print("{},__main_pkg__".format(indent))

    $DEPENDENCY_TREE_CALLS

def main():
    print("TREE DUMP:")
    dep_tree(0)
    
if __name__ == "__main__":
    main()
