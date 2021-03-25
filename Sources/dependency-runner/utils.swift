import ShellOut
import Foundation
import CryptoSwift

func mkdir_p(path: String) {
    try! shellOut(to: "mkdir", arguments: ["-p", path])
}

func cd(path: String) {
    FileManager().changeCurrentDirectoryPath(path)
}

func cp(from: String, to: String) throws {
    try shellOut(to: "cp", arguments: [from, to])
}

func cp_r(from: String, to: String) throws {
    try shellOut(to: "cp", arguments: ["-R", from, to])
}

func cp_contents(from: String, to: String) throws {
    try shellOut(to: "cp", arguments: ["-a", from + ".", to])
}

func mv(from: String, to: String) throws {
    try shellOut(to: "mv", arguments: [from, to])
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
        
        for (pkg, _) in self.main_deps {
            pkgs.insert(pkg)
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

func sha256(data: Data) -> String {
    data.sha256().toHexString()
}

func sha256(file: String) throws -> String {
    sha256(data: try Data(contentsOf: URL(fileURLWithPath: file)))
}
