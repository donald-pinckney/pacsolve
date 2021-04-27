import ShellOut

private class NpmBasedPackageManager {
    let dirManager: GenDirManager
    let lazyContextSetupCommand: String?
    let solveCommand: String
    var templateManager: TemplateManager
    let uniqueName: String
    let isReal: Bool
    
    init(uniqueName: String, isReal: Bool, lazyContextSetupCommand: String?, solveCommand: String) {
        self.uniqueName = uniqueName
        self.isReal = isReal
        self.dirManager = GenDirManager(baseName: uniqueName)
        self.templateManager = TemplateManager(templateName: isReal ? "npm-real" : "npm")
        self.lazyContextSetupCommand = lazyContextSetupCommand
        self.solveCommand = solveCommand
        self.templateManager.delegate = self
    }
}


extension NpmBasedPackageManager : PackageManager {
    func startup() {
        if !isReal {
            let configDir = self.dirManager.getConfigsDirectory().relative
            self.templateManager.instantiateTemplate(name: "configs", intoDirectory: configDir, substitutions: [:])
            startVerdaccio(configPath: configDir + "verdaccio_config.yaml")
        }
    }
    
    private func buildToRegistry(inDirectory srcDir: String) -> PublishResult {
        let buildCommand: String
        if isReal {
            // TODO: BUG: we should actually poll npm to check when the package publish has propagated.
            buildCommand =
            """
                npm publish --access public
            """
        } else {
            buildCommand =
            """
                npm publish --registry http://localhost:4873
            """
        }
        
        do {
            try shellOut(to: buildCommand, at: srcDir)
        } catch {
            return .failure(PublishError(message: "\(error)"))
        }
        return .success(())
    }
        
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) -> PublishResult {
        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
                
        templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
        
        return buildToRegistry(inDirectory: sourceDir)
    }
    
    func yank(package: Package, version: Version) -> YankResult {
        fatalError("Unimplemented")
    }
    
    func makeSolveContext() -> SolveContext {
        let contextDir = dirManager.newContextDirectory()
        
        let context = NpmSolveContext(contextDir: contextDir, templateManager: self.templateManager, lazySetupCommand: self.lazyContextSetupCommand, solveCommand: self.solveCommand)
        
        return context.solve
    }
    
    func shutdown() {
        if !isReal {
            killVerdaccio()
        }
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
            return .failure(SolveError(message: "\(error)"))
        }
    }
}

extension NpmBasedPackageManager : TemplateManagerDelegate {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
        let scopeStr = isReal ? "@wtcbkjbuzrbl/" : ""
        return [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.description,
            "$DEPENDENCIES_JSON_FRAGMENT" : dependencies.map { $0.npmFormat(isReal: isReal) }.joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.packageToDependOn) = require('\(scopeStr)\($0.packageToDependOn)');" }.joined(separator: "\n"),
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
    func npmFormat(isReal: Bool) -> String {
        if isReal {
            return "\"@wtcbkjbuzrbl/\(self.packageToDependOn)\": \"\(self.constraint.npmFormat())\""
        } else {
            return "\"\(self.packageToDependOn)\": \"\(self.constraint.npmFormat())\""

        }
    }
}


func Npm() -> PackageManager {
    let solveCommand =
    """
        npm install --silent --registry http://localhost:4873
        node index.js
    """
    
    return NpmBasedPackageManager(uniqueName: "npm", isReal: false, lazyContextSetupCommand: nil, solveCommand: solveCommand)
}

func Yarn1() -> PackageManager {
    let solveCommand =
    """
        yarn install --silent --registry http://localhost:4873
        node index.js
    """
    
    return NpmBasedPackageManager(uniqueName: "yarn1", isReal: false, lazyContextSetupCommand: nil, solveCommand: solveCommand)
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
    
    return NpmBasedPackageManager(uniqueName: "yarn2", isReal: false, lazyContextSetupCommand: lazyContextSetupCommand, solveCommand: solveCommand)
}


func NpmReal() -> PackageManager {
    let solveCommand =
    """
        npm install --silent
        node index.js
    """
    
    return WaitForUpdateManager(
            wrapping: NpmBasedPackageManager(uniqueName: "npm-real", isReal: true, lazyContextSetupCommand: nil, solveCommand: solveCommand),
            sleepTime: 60)
}

func Yarn1Real() -> PackageManager {
    let solveCommand =
    """
        yarn install --silent
        node index.js
    """
    
    return WaitForUpdateManager(
            wrapping: NpmBasedPackageManager(uniqueName: "yarn1-real", isReal: true, lazyContextSetupCommand: nil, solveCommand: solveCommand),
            sleepTime: 60)
}

func Yarn2Real() -> PackageManager {
    let lazyContextSetupCommand =
    """
        rm -rf ~/.yarn/berry/cache
        yarn set version berry
    """
    
    let solveCommand =
    """
        yarn install --silent
        yarn node index.js
    """
    
    return WaitForUpdateManager(
            wrapping: NpmBasedPackageManager(uniqueName: "yarn2-real", isReal: true, lazyContextSetupCommand: lazyContextSetupCommand, solveCommand: solveCommand),
            sleepTime: 60)
}
