import ShellOut
import Foundation

func mkdir_p(path: String) {
    try! shellOut(to: "mkdir", arguments: ["-p", path])
}

func cd(path: String) {
    FileManager().changeCurrentDirectoryPath(path)
}

func projectRootDir() -> URL {
    let myPath = URL(fileURLWithPath: #filePath)
    return myPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}

func changeToProjectRoot() {
    cd(path: projectRootDir().path)
}

func absolutePathRelativeToProjectRoot(forPath: String) -> String {
    var p: String
    if forPath.starts(with: "/") {
        p = forPath
        p.removeFirst()
    } else {
        p = forPath
    }
    return projectRootDir().path + "/" + p
}

extension Dependencies {
    func allPackages() -> [Package] {
        // TODO: Stabilize the order of this set, since it might matter!
        
        var pkgs: Set<Package> = Set()
        
        for (pkg, pkg_deps) in self.non_main_deps {
            pkgs.insert(pkg)
            for (_, ds) in pkg_deps {
                for (p, _) in ds {
                    pkgs.insert(p)
                }
            }
        }
        
        return [Package](pkgs).sorted { $0.name < $1.name }
    }
}


extension String {
    func quoted() -> String {
        "'\(self)'"
    }
}

var _debug = false

func debugLogging(on: Bool) {
    _debug = on
}

func logDebug(_ x: String) {
    if _debug {
        print(x)
    }
}
