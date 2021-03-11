import ShellOut

func mkdir_p(path: String) {
    try! shellOut(to: "mkdir", arguments: ["-p", path])
}

extension Dependencies {
    func allPackages() -> [Package] {
        var pkgs: Set<Package> = Set()
        
        for (pkg, pkg_deps) in self.non_main_deps {
            pkgs.insert(pkg)
            for (_, ds) in pkg_deps {
                for (p, _) in ds {
                    pkgs.insert(p)
                }
            }
        }
        
        return [Package](pkgs)
    }
}


extension String {
    func quoted() -> String {
        "'\(self)'"
    }
}
