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

    private func buildCrate(inDirectory srcDir: String, package: Package, version: Version, dependencies: [DependencyExpr]) throws -> (crateBytes: Data, crateFilename: String, metadata: CrateMetadata) {

        try! shellOut(to: "cargo", arguments: ["package", "--no-verify", "--allow-dirty","--offline"], at: srcDir)
        let crateFilename = "\(package)-\(version).crate"
        let cratePath = "\(srcDir)target/package/\(crateFilename)"
        let crateURL = URL(fileURLWithPath: cratePath, isDirectory: false)
        let crateBytes = try! Data(contentsOf: crateURL)
        let crateSha = crateBytes.sha256().toHexString()
    
        let depsMeta = try dependencies.map { CrateMetadata.MetaDependency(name: $0.packageToDependOn.name, req: try $0.constraint.cargoFormat()) }
        
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
        
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) -> PublishResult {
//        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
        let sourceDir = dirManager.newSourceDirectory(package: package, version: version)
        
        let buildResult: (crateBytes: Data, crateFilename: String, metadata: CrateMetadata)
        do {
            try templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
            buildResult = try buildCrate(inDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
        } catch {
            return .failure(PublishError(message: "\(error)"))
        }
        
        let packagesDir = URL(fileURLWithPath: dirManager.getUniqueDirectory(name: "registry/packages").relative, isDirectory: true)
        let packageDest = packagesDir.appendingPathComponent(buildResult.crateFilename, isDirectory: false)
        try! buildResult.crateBytes.write(to: packageDest)
        
        writeRegistryUpdate(metadata: buildResult.metadata)
        
        try! shellOut(to: "git add . && git commit -m x", at: self.dirManager.getRegistryDirectory().relative)
        
        return .success(())
    }
    
    func yank(package: Package, version: Version) -> YankResult {
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
        do {
            try templateManager.instantiateContextTemplate(intoDirectory: contextDir, package: "context", version: "0.0.1", dependencies: dependencies)
        } catch {
            return .failure(SolveError(message: "\(error)"))
        }
        
        let solveCommand =
        #"""
            cargo run
        """#
        
        do {
            let output = try shellOut(to: solveCommand, at: self.contextDir)
            var parser = SolutionTreeParser(toParse: output)
            return parser.parseSolutionTree()
        } catch {
            return .failure(SolveError(message: "\(error)"))
        }
    }
}

extension Cargo : TemplateManagerDelegate {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) throws -> [String : String] {
        let depStrings = try dependencies.map { try $0.cargoFormat() }
        return [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.description,
            "$REGISTRY_DIR" : self.dirManager.getRegistryDirectory().absolute,
            "$DEPENDENCIES_TOML_FRAGMENT" : depStrings.joined(separator: "\n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "use \($0.packageToDependOn);" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn)::dep_tree(indent + 1, do_inc);" }.joined(separator: "\n    ")
        ]
    }
}

extension ConstraintExpr {
    func cargoFormat() throws -> String {
        switch self {
            case .wildcardMajor:
                return "*"
            case .exactly(let v):
                return "= \(v)"
            case .geq(let v):
                return ">=\(v)"
            case .gt(let v):
                return ">\(v)"
            case .leq(let v):
                return "<=\(v)"
            case .lt(let v):
                return "<\(v)"
            case .caret(let v):
                return "^\(v)"
            case .tilde(let v):
                return "~\(v)"
            case let .and(c1, c2):
                return try "\(c1.cargoFormat()), \(c2.cargoFormat())"
            case let .or(c1, c2):
                throw UnsupportedConstraintError(constraint: self)
            case let .wildcardBug(major, minor):
                return "\(major).\(minor).x"
            case let .wildcardMinor(major):
                return "\(major).x"
            case .not(_):
                throw UnsupportedConstraintError(constraint: self)
        }
    }
}

extension DependencyExpr {
    func cargoFormat() throws -> String {
        "\(self.packageToDependOn) = { version = \"\(try self.constraint.cargoFormat())\", registry = \"local\" }"
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
