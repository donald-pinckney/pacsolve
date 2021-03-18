import Files
import ShellOut
import Foundation

struct Cargo : PackageManagerWithRegistry {
    
    struct PackageVersionMetadata: Encodable {
        struct MetaDependency: Encodable {
            let name: String
            let req: String
            let features: [String] = []
            let optional = false
            let default_features = true
            let target: String? = nil
            let kind = "normal"
        }
        
        let name: String
        let vers: String
        let deps: [MetaDependency]
        let cksum: String
        let features: [String : [String]] = [:]
        let yanked = false
    }
    
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
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "use \($0.0.name);" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name)::dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions: [String : String] = [
            "$DEPENDENCIES_TOML_FRAGMENT" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
            "$REGISTRY_DIR" : self.absoluteGenRegistryDir,
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "use \($0.0.name);" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name)::dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, pkgDir: String, dependencies: [(Package, VersionSpecifier)]) -> PackageVersionMetadata {
        print("Publishing: \(pkgDir)")
        
        try! shellOut(to: "git init && git add . && git commit -m x", at: pkgDir)

        try! shellOut(to: "cargo", arguments: ["package", "--no-verify", "--offline"], at: pkgDir)
        let cratePath = "\(pkgDir)target/package/\(package.name)-\(version.semverName).crate"
        try! shellOut(to: "cp", arguments: [cratePath, self.genRegistryPackagesPathDir])
        
        let cksum = try! sha256(file: cratePath)
        
        let depsMeta = dependencies.map { PackageVersionMetadata.MetaDependency(name: $0.0.name, req: versionSpecStr($0.1)) }
        
        return PackageVersionMetadata(name: package.name, vers: version.semverName, deps: depsMeta, cksum: cksum)
    }
    
    
    func appendMetaData(meta: PackageVersionMetadata, dirs: inout Set<String>, files: inout [String : [Data]]) {
        let regRelativePath: String
        if meta.name.count == 1 {
            regRelativePath = "1/"
        } else if meta.name.count == 2 {
            regRelativePath = "2/"
        } else if meta.name.count == 3 {
            regRelativePath = "3/\(meta.name.first!)/"
        } else {
            let index0 = meta.name.startIndex
            let index2 = meta.name.index(meta.name.startIndex, offsetBy: 2)
            let index4 = meta.name.index(index2, offsetBy: 2)
            regRelativePath = "\(meta.name[index0..<index2])/\(meta.name[index2..<index4])/"
        }
        
        let dirPath = "\(self.genRegistryPathDir)\(regRelativePath)"
        dirs.insert(dirPath)
        
        let jsonPath = "\(dirPath)\(meta.name)"
        
        let jsonData = try! JSONEncoder().encode(meta)
        files[jsonPath, default: []].append(jsonData)
    }
    
    func finalizeRegistry(publishingData: [Package : [Version : PackageVersionMetadata]]) {
        var dirs: Set<String> = Set()
        var files: [String : [Data]] = [:]
        
        for (_, versionMetas) in publishingData {
            for version in versionMetas.keys.sorted(by: <) {
                let meta = versionMetas[version]!
                appendMetaData(meta: meta, dirs: &dirs, files: &files)
            }
        }
        
        for d in dirs {
            mkdir_p(path: d)
        }
        
        for (f, lines) in files {
            let linesConcat = Data(lines.joined(separator: Character("\n").utf8))
            try! linesConcat.write(to: URL(fileURLWithPath: f))
        }
        
        try! shellOut(to: "git init && git add . && git commit -m x", at: self.genRegistryPathDir)
    }
    
    func solveCommand(forMainPath mainPath: String) -> SolveCommand {
        let solver = SolveCommand(directory: mainPath, command: """
            echo "TREE DUMP:"
            cargo tree --no-dedupe
        """, packageManager: self)
        
        return solver
    }
    
    func cleanup() {
        
    }
}



