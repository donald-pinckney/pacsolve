import ShellOut
import Foundation

class Cargo {
    let dirManager = GenDirManager(baseName: "cargo")
    var templateManager = TemplateManager(templateName: "cargo")
    
    var registryConfigPath: String {
        self.dirManager.getRegistryDirectory().relative + "config.json"
    }
    
    init() {
        self.templateManager.delegate = self
        
        initRegistry()
    }
    
    func initRegistry() {
        let regPath = self.dirManager.getRegistryDirectory()
        let packagesPath = self.dirManager.getUniqueDirectory(name: "registry/packages")
        templateManager.instantiateTemplate(name: "registry", intoDirectory: regPath.relative, substitutions: ["$ABSOLUTE_REGISTRY_PACKAGES_DIR" : packagesPath.absolute])
        
        try! shellOut(to: "git init && git add . && git commit -m x", at: regPath.relative)
    }
}

extension Cargo : PackageManager {
    var uniqueName: String { "cargo" }

    private func buildCrate(inDirectory srcDir: String, package: Package, version: Version, dependencies: [DependencyExpr]) -> (crateBytes: Data, crateFilename: String, metadata: CrateMetadata) {

        try! shellOut(to: "cargo", arguments: ["package", "--no-verify", "--allow-dirty","--offline"], at: srcDir)
        let crateFilename = "\(package)-\(version).crate"
        let cratePath = "\(srcDir)target/package/\(crateFilename)"
        let crateURL = URL(fileURLWithPath: cratePath, isDirectory: false)
        let crateBytes = try! Data(contentsOf: crateURL)
        let crateSha = crateBytes.sha256().toHexString()
    
        let depsMeta = dependencies.map { CrateMetadata.MetaDependency(name: $0.packageToDependOn.name, req: $0.constraint.cargoFormat()) }
        
        return (crateBytes: crateBytes, crateFilename: crateFilename, metadata: CrateMetadata(name: package.name, vers: version.description, deps: depsMeta, cksum: crateSha))
    }
    
    func writeRegistryUpdate(metadata meta: CrateMetadata) {
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

        let dirURL = URL(fileURLWithPath: self.dirManager.getUniqueDirectory(name: "registry/\(regRelativePath)").relative, isDirectory: true)

        let jsonURL = dirURL.appendingPathComponent(meta.name, isDirectory: false)
        var jsonData = try! JSONEncoder().encode(meta)
        jsonData.append("\n".data(using: .utf8)!)

        // From: https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
        do {
            let fileHandle = try FileHandle(forWritingTo: jsonURL)
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(jsonData)
        } catch {
            try! jsonData.write(to: jsonURL)
        }
    }
        
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) {
        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
                
        templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
        
        let buildResult = buildCrate(inDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
        
        let packagesDir = URL(fileURLWithPath: dirManager.getUniqueDirectory(name: "registry/packages").relative, isDirectory: true)
        let packageDest = packagesDir.appendingPathComponent(buildResult.crateFilename, isDirectory: false)
        try! buildResult.crateBytes.write(to: packageDest)
        
        writeRegistryUpdate(metadata: buildResult.metadata)
        
        try! shellOut(to: "git add . && git commit -m x", at: self.dirManager.getRegistryDirectory().relative)
    }
    
    func yank(package: Package, version: Version) {
        fatalError("Unimplemented")
    }
    
    func makeSolveContext() -> SolveContext {
        let contextDir = dirManager.newContextDirectory()
        
        let context = CargoSolveContext(contextDir: contextDir, templateManager: self.templateManager)
        return context.solve
    }
    
    func startup() {}
    func shutdown() {}
}

class CargoSolveContext {
    let contextDir: String
    let templateManager: TemplateManager
    
    init(contextDir: String, templateManager: TemplateManager) {
        self.contextDir = contextDir
        self.templateManager = templateManager
    }
    
    func solve(dependencies: [DependencyExpr]) -> SolveResult {
        templateManager.instantiatePackageTemplate(intoDirectory: contextDir, package: "context", version: "0.0.1", dependencies: dependencies)
                
        let solveCommand =
        #"""
            echo "TREE DUMP:"
            cargo tree --no-dedupe --prefix depth --format ,{p} | sed 's/ (.*//g'
        """#
        
        do {
            let output = try shellOut(to: solveCommand, at: self.contextDir)
            var parser = SolutionTreeParser(toParse: output)
            return parser.parseSolutionTree()
        } catch {
            return .solveError("\(error)")
        }
    }
}

extension Cargo : TemplateManagerDelegate {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
        [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.description,
            "$REGISTRY_DIR" : self.dirManager.getRegistryDirectory().absolute,
            "$DEPENDENCIES_TOML_FRAGMENT" : dependencies.map { $0.cargoFormat() }.joined(separator: "\n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "use \($0.packageToDependOn);" }.joined(separator: "\n"),
//            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn)::dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
    }
}

extension ConstraintExpr {
    func cargoFormat() -> String {
        switch self {
            case .any:
                return "*"
            case .exactly(let v):
                return "= \(v)"
//            case .geq(let v):
//                return ">=\(v.semverName)"
//            case .gt(let v):
//                return ">\(v.semverName)"
//            case .leq(let v):
//                return "<=\(v.semverName)"
//            case .lt(let v):
//                return "<\(v.semverName)"
//            case .caret(let v):
//                return "^\(v.semverName)"
//            case .tilde(let v):
//                return "~\(v.semverName)"
        }
    }
}

extension DependencyExpr {
    func cargoFormat() -> String {
        "\(self.packageToDependOn) = { version = \"\(self.constraint.cargoFormat())\", registry = \"local\" }"
    }
}


struct CrateMetadata: Encodable {
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
