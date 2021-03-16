import Files
import ShellOut

struct Cargo : PackageManagerWithRegistry {
    let name = "cargo"
    
    func initRegistry() {
//        run(script: "init_registry.sh", arguments: [])
    }
    
    
//    func versionSpecStr(_ vs: VersionSpecifier) -> String {
//        switch vs {
//        case .any:
//            return ""
//        case .exactly(let v):
//            return "\(v.semverName)"
//        }
//    }
//
//    func formatDepenency(dep: (Package, VersionSpecifier)) -> String {
//        "\"\(dep.0.name)\": \"\(self.versionSpecStr(dep.1))\""
//    }
    
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions: [String : String] = [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.semverName,
//            "$DEPENDENCIES_JSON_FRAGMENT" : dependencies.map(self.formatDepenency).joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.0.name) = require('\($0.0.name)');" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions: [String : String] = [
//            "$DEPENDENCIES_JSON_FRAGMENT" : dependencies.map(self.formatDepenency).joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.0.name) = require('\($0.0.name)');" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, pkgDir: String) {
//        print("Publishing: \(pkgDir)")
    }
    
    
    func solveCommand(forMainPath mainPath: String) -> SolveCommand {
        let solver = SolveCommand(directory: mainPath, command: """
            cargo run
        """, packageManager: self)
        
        return solver
    }
    
    func cleanup() {
        
    }
}
