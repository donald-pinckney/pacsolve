import ShellOut

private class NpmBasedPackageManager {
    let dirManager: GenDirManager
    let lazyContextSetupCommand: String?
    let solveCommand: String
    var templateManager = TemplateManager(templateName: "npm")
    let uniqueName: String
    
    init(uniqueName: String, lazyContextSetupCommand: String?, solveCommand: String) {
        self.uniqueName = uniqueName
        self.dirManager = GenDirManager(baseName: uniqueName)
        self.lazyContextSetupCommand = lazyContextSetupCommand
        self.solveCommand = solveCommand
        self.templateManager.delegate = self
    }
}


extension NpmBasedPackageManager : PackageManager {
    func startup() {
        let configDir = self.dirManager.getConfigsDirectory().relative
        self.templateManager.instantiateTemplate(name: "configs", intoDirectory: configDir, substitutions: [:])
        startVerdaccio(configPath: configDir + "verdaccio_config.yaml")
    }
    
    private func buildToRegistry(inDirectory srcDir: String) {
        let buildCommand =
        """
            npm publish --registry http://localhost:4873
        """
        
        try! shellOut(to: buildCommand, at: srcDir)
    }
        
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) {
        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
                
        templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
        
        buildToRegistry(inDirectory: sourceDir)
    }
    
    func yank(package: Package, version: Version) {
        fatalError("Unimplemented")
    }
    
    func makeSolveContext() -> SolveContext {
        let contextDir = dirManager.newContextDirectory()
        
        let context = NpmSolveContext(contextDir: contextDir, templateManager: self.templateManager, lazySetupCommand: self.lazyContextSetupCommand, solveCommand: self.solveCommand)
        
        return context.solve
    }
    
    func shutdown() {
        killVerdaccio()
    }
}

class NpmSolveContext {
    let contextDir: String
    let templateManager: TemplateManager
    let lazySetupCommand: String?
    let solveCommand: String
    
    var didLazySetup = false
    
    init(contextDir: String, templateManager: TemplateManager, lazySetupCommand: String?, solveCommand: String) {
        self.contextDir = contextDir
        self.templateManager = templateManager
        self.lazySetupCommand = lazySetupCommand
        self.solveCommand = solveCommand
    }
    
    func solve(dependencies: [DependencyExpr]) -> SolveResult {
        templateManager.instantiatePackageTemplate(intoDirectory: contextDir, package: "context", version: "0.0.1", dependencies: dependencies)
        
        if !didLazySetup {
            if let setup = self.lazySetupCommand {
                try! shellOut(to: setup, at: self.contextDir)
            }
            didLazySetup = true
        }

        do {
            let output = try shellOut(to: self.solveCommand, at: self.contextDir)
            var parser = SolutionTreeParser(toParse: output)
            return parser.parseSolutionTree()
        } catch {
            return .solveError("\(error)")
        }
    }
}

extension NpmBasedPackageManager : TemplateManagerDelegate {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
        [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.description,
            "$DEPENDENCIES_JSON_FRAGMENT" : dependencies.map { $0.npmFormat() }.joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.packageToDependOn) = require('\($0.packageToDependOn)');" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn).dep_tree(indent + 1);" }.joined(separator: "\n    ")
        ]
    }
}

extension ConstraintExpr {
    func npmFormat() -> String {
        switch self {
            case .any:
                return "*"
            case .exactly(let v):
                return "\(v)"
    //        case .geq(let v):
    //            return ">=\(v.semverName)"
    //        case .gt(let v):
    //            return ">\(v.semverName)"
    //        case .leq(let v):
    //            return "<=\(v.semverName)"
    //        case .lt(let v):
    //            return "<\(v.semverName)"
    //        case .caret(let v):
    //            return "^\(v.semverName)"
    //        case .tilde(let v):
    //            return "~\(v.semverName)"
        }
    }
}

extension DependencyExpr {
    func npmFormat() -> String {
        "\"\(self.packageToDependOn)\": \"\(self.constraint.npmFormat())\""
    }
}


func Npm() -> PackageManager {
    let solveCommand =
    """
        npm install --silent --registry http://localhost:4873
        node index.js
    """
    
    return NpmBasedPackageManager(uniqueName: "npm", lazyContextSetupCommand: nil, solveCommand: solveCommand)
}

func Yarn1() -> PackageManager {
    let solveCommand =
    """
        yarn install --silent --registry http://localhost:4873
        node index.js
    """
    
    return NpmBasedPackageManager(uniqueName: "yarn1", lazyContextSetupCommand: nil, solveCommand: solveCommand)
}

func Yarn2() -> PackageManager {
    let lazyContextSetupCommand =
    """
        rm -rf ~/.yarn/berry/cache
        yarn set version berry
        yarn config set npmRegistryServer http://localhost:4873
        yarn config set unsafeHttpWhitelist localhost
    """
    
    let solveCommand =
    """
        yarn install --silent
        yarn node index.js
    """
    
    return NpmBasedPackageManager(uniqueName: "yarn2", lazyContextSetupCommand: lazyContextSetupCommand, solveCommand: solveCommand)
}
