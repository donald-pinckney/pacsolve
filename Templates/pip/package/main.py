import pkg_src

def main():
    print("TREE DUMP:")
    pkg_src.dep_tree(0, True)
    
if __name__ == "__main__":
    main()
