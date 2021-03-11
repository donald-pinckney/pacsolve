import ShellOut
import Foundation

func mkdir_p(path: String) {
    try! shellOut(to: "mkdir", arguments: ["-p", path])
}

func cd(path: String) {
    FileManager().changeCurrentDirectoryPath(path)
}

func changeToProjectRoot() {
    let myPath = URL(fileURLWithPath: #filePath)

    let projectRoot = myPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path
    FileManager().changeCurrentDirectoryPath(projectRoot)
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
