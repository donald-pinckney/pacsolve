import Files
import ShellOut

struct CargoPackageVersionMetadata {
    struct CargoPackageVersionMetadataDependency {
        let name: String
        let req: String
    }
    
    let name: String
    let vers: String
    let deps: [CargoPackageVersionMetadataDependency]
    let cksum: String
}


struct Cargo : PackageManagerWithRegistry {
    let name = "cargo"
    
    var genRegistryPathDir: String {
        get {
            "generated/\(self.name)/registry/"
        }
    }
    
    var genRegistryPackagesPathDir: String {
        get {
            "generated/\(self.name)/registry/packages/"
        }
    }
    
    var absoluteGenRegistryDir: String {
        get {
            absolutePathRelativeToProjectRoot(forPath: genRegistryPathDir)
        }
    }
    
    var registryConfigPath: String {
        get {
            "generated/\(self.name)/registry/config.json"
        }
    }
    
    func initRegistry() {
        mkdir_p(path: self.genRegistryPackagesPathDir)
        let jsonContents = #"{"dl": "file://\#(self.absoluteGenRegistryDir)packages/{crate}-{version}.crate"}"#
        try! jsonContents.write(toFile: self.registryConfigPath, atomically: false, encoding: .utf8)
    }
    
    
    
    
    func versionSpecStr(_ vs: VersionSpecifier) -> String {
        switch vs {
        case .any:
            return "*"
        case .exactly(let v):
            return "\(v.semverName)"
        }
    }

    func formatDepenency(dep: (Package, VersionSpecifier)) -> String {
        "\(dep.0.name) = { version = \"\(self.versionSpecStr(dep.1))\", registry = \"local\" }"
    }
    
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions: [String : String] = [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.semverName,
            "$REGISTRY_DIR" : self.absoluteGenRegistryDir,
            "$DEPENDENCIES_TOML_FRAGMENT" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.0.name) = require('\($0.0.name)');" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions: [String : String] = [
            "$DEPENDENCIES_TOML_FRAGMENT" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
            "$REGISTRY_DIR" : self.absoluteGenRegistryDir,
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.0.name) = require('\($0.0.name)');" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, pkgDir: String) {
        print("Publishing: \(pkgDir)")
        
        try! shellOut(to: "cargo", arguments: ["package", "--allow-dirty", "--no-verify", "--offline"], at: pkgDir)
        try! shellOut(to: "cp", arguments: ["\(pkgDir)target/package/*.crate", self.genRegistryPackagesPathDir])
    }
    
    
    func solveCommand(forMainPath mainPath: String) -> SolveCommand {
        let solver = SolveCommand(directory: mainPath, command: """
            # cargo run
        """, packageManager: self)
        
        return solver
    }
    
    func cleanup() {
        
    }
}
