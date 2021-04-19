import Files
import ShellOut
import Foundation

//struct Cargo : PackageManagerWithRegistry {
//    init() {}
//
//    struct PackageVersionMetadata: Encodable {
//        struct MetaDependency: Encodable {
//            let name: String
//            let req: String
//            let features: [String] = []
//            let optional = false
//            let default_features = true
//            let target: String? = nil
//            let kind = "normal"
//        }
//        
//        let name: String
//        let vers: String
//        let deps: [MetaDependency]
//        let cksum: String
//        let features: [String : [String]] = [:]
//        let yanked = false
//    }
//    
//    let uniqueName: String = "cargo"
//    
//    var genRegistryPathDir: String {
//        get {
//            "generated/\(self.uniqueName)/registry/"
//        }
//    }
//    
//    var genRegistryPackagesPathDir: String {
//        get {
//            "generated/\(self.uniqueName)/registry/packages/"
//        }
//    }
//    
//    var absoluteGenRegistryDir: String {
//        get {
//            absolutePathRelativeToProjectRoot(forPath: genRegistryPathDir)
//        }
//    }
//    
//    var registryConfigPath: String {
//        get {
//            "generated/\(self.uniqueName)/registry/config.json"
//        }
//    }
//    
//    func generatedDirectoryFor(package: Package, version: Version) -> String {
//        "\(genSourcesPathDir)\(package)/\(version.directoryName)/"
//    }
//    
//    func initRegistry() {
//        mkdir_p(path: self.genRegistryPackagesPathDir)
//        let jsonContents = #"{"dl": "file://\#(self.absoluteGenRegistryDir)packages/{crate}-{version}.crate"}"#
//        try! jsonContents.write(toFile: self.registryConfigPath, atomically: false, encoding: .utf8)
//    }
//    
//    
//    
//    func constraintStr(_ c: ConstraintExpr) -> String {
//        switch c {
//        case .any:
//            return "*"
//        case .exactly(let v):
//            return "= \(v.semverName)"
////        case .geq(let v):
////            return ">=\(v.semverName)"
////        case .gt(let v):
////            return ">\(v.semverName)"
////        case .leq(let v):
////            return "<=\(v.semverName)"
////        case .lt(let v):
////            return "<\(v.semverName)"
////        case .caret(let v):
////            return "^\(v.semverName)"
////        case .tilde(let v):
////            return "~\(v.semverName)"
//        }
//    }
//
//    func formatDepenency(dep: DependencyExpr) -> String {
//        "\(dep.packageToDependOn) = { version = \"\(self.constraintStr(dep.constraint))\", registry = \"local\" }"
//    }
//    
//    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
//        let substitutions: [String : String] = [
//            "$NAME_STRING" : package.name,
//            "$VERSION_STRING" : version.semverName,
//            "$REGISTRY_DIR" : self.absoluteGenRegistryDir,
//            "$DEPENDENCIES_TOML_FRAGMENT" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "use \($0.packageToDependOn);" }.joined(separator: "\n"),
//            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn)::dep_tree(indent + 1);" }.joined(separator: "\n    ")
//        ]
//        return substitutions
//    }
//    
//    func publish(package: Package, version: Version, pkgDir: String, dependencies: [DependencyExpr]) -> PackageVersionMetadata {
////        print("Publishing: \(pkgDir)")
//        
////        try! shellOut(to: "git init && git add . && git commit -m x", at: pkgDir)
//
//        try! shellOut(to: "cargo", arguments: ["package", "--no-verify", "--allow-dirty","--offline"], at: pkgDir)
//        let cratePath = "\(pkgDir)target/package/\(package)-\(version.semverName).crate"
//        try! shellOut(to: "cp", arguments: [cratePath, self.genRegistryPackagesPathDir])
//        
//        let cksum = try! sha256(file: cratePath)
//        
//        let depsMeta = dependencies.map { PackageVersionMetadata.MetaDependency(name: $0.packageToDependOn.name, req: constraintStr($0.constraint)) }
//        
//        return PackageVersionMetadata(name: package.name, vers: version.semverName, deps: depsMeta, cksum: cksum)
//    }
//    
//    
//    func appendMetaData(meta: PackageVersionMetadata, dirs: inout Set<String>, files: inout [String : [Data]]) {
//        let regRelativePath: String
//        if meta.name.count == 1 {
//            regRelativePath = "1/"
//        } else if meta.name.count == 2 {
//            regRelativePath = "2/"
//        } else if meta.name.count == 3 {
//            regRelativePath = "3/\(meta.name.first!)/"
//        } else {
//            let index0 = meta.name.startIndex
//            let index2 = meta.name.index(meta.name.startIndex, offsetBy: 2)
//            let index4 = meta.name.index(index2, offsetBy: 2)
//            regRelativePath = "\(meta.name[index0..<index2])/\(meta.name[index2..<index4])/"
//        }
//        
//        let dirPath = "\(self.genRegistryPathDir)\(regRelativePath)"
//        dirs.insert(dirPath)
//        
//        let jsonPath = "\(dirPath)\(meta.name)"
//        
//        let jsonData = try! JSONEncoder().encode(meta)
//        files[jsonPath, default: []].append(jsonData)
//    }
//    
//    func finalizeRegistry(publishingData: [Package : [Version : PackageVersionMetadata]]) {
//        var dirs: Set<String> = Set()
//        var files: [String : [Data]] = [:]
//        
//        for (_, versionMetas) in publishingData {
//            for version in versionMetas.keys.sorted(by: <) {
//                let meta = versionMetas[version]!
//                appendMetaData(meta: meta, dirs: &dirs, files: &files)
//            }
//        }
//        
//        for d in dirs {
//            mkdir_p(path: d)
//        }
//        
//        for (f, lines) in files {
//            let linesConcat = Data(lines.joined(separator: Character("\n").utf8))
//            try! linesConcat.write(to: URL(fileURLWithPath: f))
//        }
//        
//        try! shellOut(to: "git init && git add . && git commit -m x", at: self.genRegistryPathDir)
//    }
//    
//    func parseSingleTreePackageLine(line: Substring) -> (Int, Package, Version) {
//        cargoStyle_parseSingleTreePackageLine(line: line)
//    }
//    
//    func solveCommand(package: Package, version: Version) -> String {
//        #"""
//            echo "TREE DUMP:"
//            cargo tree --no-dedupe --prefix depth --format ,{p} | sed 's/ (.*//g'
//        """#        
//    }
//    
//    func cleanup() {
//        
//    }
//}
//
//
//func cargoStyle_parseSingleTreePackageLine(line: Substring) -> (Int, Package, Version) {
//    let commaIdx = line.firstIndex(of: ",")!
//    let after = line[line.index(after: commaIdx)..<line.endIndex]
//    let before = line[line.startIndex..<commaIdx]
//    let indentSize = Int(before)!
//    
//    let vIdx = after.lastIndex(of: "v")!
//    
//    let versionStart = after.index(after: vIdx)
//    let nameEnd = after.index(before: vIdx)
//    
//    return (indentSize, Package(stringLiteral: String(after[after.startIndex..<nameEnd])), Version(stringLiteral: String(after[versionStart..<after.endIndex])))
//}
