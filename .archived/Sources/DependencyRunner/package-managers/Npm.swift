import ShellOut


let SCOPE_STR = "@minnpm-artifact-examples"

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


extension NpmBasedPackageManager : InternalPackageManager {
    var shouldRenameVars: Bool { 
        false
        // isReal 
    }
    
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
//        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
        let sourceDir = dirManager.newSourceDirectory(package: package, version: version)
        
        do {
            try templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
        } catch {
            return .failure(PublishError(message: "\(error)"))
        }
        
        return buildToRegistry(inDirectory: sourceDir)
    }
    
    func yank(package: Package, version: Version) -> YankResult {
        let srcDir = dirManager.newSourceDirectory(package: package, version: version)
        
        let yankCommand: String
        if isReal {
            yankCommand =
            """
                npm deprecate \(SCOPE_STR)/\(package)@\(version) "x"
            """
        } else {
            yankCommand =
            """
                npm deprecate --registry http://localhost:4873 \(SCOPE_STR)/\(package)@\(version) "x"
            """
        }
        
        do {
            try shellOut(to: yankCommand, at: srcDir)
        } catch {
            return .failure(YankError(message: "\(error)"))
        }
        return .success(())
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
    
    func solve(dependencies: [DependencyExpr]) -> SolveResult<Int> {
        
        do {
            try templateManager.instantiatePackageTemplate(intoDirectory: contextDir, package: "context", version: "0.0.1", dependencies: dependencies)
        } catch {
            return .failure(SolveError(message: "\(error)"))
        }
        
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
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) throws -> [String : String] {
        let scopeStr = SCOPE_STR
        let prodDepStrings = try dependencies.filter { $0.depType == .prod }.map { try $0.npmFormat() }
        let devDepStrings = try dependencies.filter { $0.depType == .dev }.map { try $0.npmFormat() }
        let peerDepStrings = try dependencies.filter { $0.depType == .peer }.map { try $0.npmFormat() }
        let optionalDepStrings = try dependencies.filter { $0.depType == .optional }.map { try $0.npmFormat() }

        return [
            "$SCOPE_STR" : scopeStr,
            "$NAME_STRING" : package.description,
            "$VERSION_STRING" : version.description,
            "$DEPENDENCIES_PROD_JSON_FRAGMENT" : prodDepStrings.joined(separator: ", \n"),
            "$DEPENDENCIES_DEV_JSON_FRAGMENT" : devDepStrings.joined(separator: ", \n"),
            "$DEPENDENCIES_PEER_JSON_FRAGMENT" : peerDepStrings.joined(separator: ", \n"),
            "$DEPENDENCIES_OPTIONAL_JSON_FRAGMENT" : optionalDepStrings.joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.packageToDependOn) = require('\(scopeStr)\($0.packageToDependOn)');" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn).dep_tree(indent + 1, do_inc);" }.joined(separator: "\n    "),
        ]
    }
}

extension ConstraintExpr {
    func npmFormat() throws -> String {
        switch self {
            case .wildcardMajor:
                return "*"
            case .exactly(let v):
                return "\(v)"
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
                return try "\(c1.npmFormat()) \(c2.npmFormat())"
            case let .or(c1, c2):
                return try "\(c1.npmFormat()) || \(c2.npmFormat())"
            case let .wildcardBug(major, minor):
                return "\(major).\(minor).x"
            case let .wildcardMinor(major):
                return "\(major).x"
            case .not(_):
                throw UnsupportedConstraintError(constraint: self)
            case .other(let o):
                return o
        }
    }
}

extension DependencyExpr {
    func npmFormat() throws -> String {
        return "\"\(SCOPE_STR)/\(self.packageToDependOn)\": \"\(try self.constraint.npmFormat())\""
    }
}


func Npm() -> LocalPackageManager {
    let solveCommand =
    """
        npm install --silent --registry http://localhost:4873
        node index.js
    """
    
    return LocalPackageManager(pm: NpmBasedPackageManager(uniqueName: "npm", isReal: false, lazyContextSetupCommand: nil, solveCommand: solveCommand))
}

func Yarn1() -> LocalPackageManager {
    let solveCommand =
    """
        yarn install --silent --registry http://localhost:4873
        node index.js
    """
    
    return LocalPackageManager(pm: NpmBasedPackageManager(uniqueName: "yarn1", isReal: false, lazyContextSetupCommand: nil, solveCommand: solveCommand))
}

func Yarn2() -> LocalPackageManager {
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
    
    return LocalPackageManager(pm: NpmBasedPackageManager(uniqueName: "yarn2", isReal: false, lazyContextSetupCommand: lazyContextSetupCommand, solveCommand: solveCommand))
}


func NpmReal() -> LocalPackageManager {
    let solveCommand =
    """
        npm install --silent
        node index.js
    """
    
    return LocalPackageManager(pm: WaitForUpdateManager(
            wrapping: NpmBasedPackageManager(uniqueName: "npm-real", isReal: true, lazyContextSetupCommand: nil, solveCommand: solveCommand),
            sleepTime: 60))
}

func Yarn1Real() -> LocalPackageManager {
    let solveCommand =
    """
        yarn install --silent
        node index.js
    """
    
    return LocalPackageManager(pm: WaitForUpdateManager(
            wrapping: NpmBasedPackageManager(uniqueName: "yarn1-real", isReal: true, lazyContextSetupCommand: nil, solveCommand: solveCommand),
            sleepTime: 60))
}

func Yarn2Real() -> LocalPackageManager {
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
    
    return LocalPackageManager(pm: WaitForUpdateManager(
            wrapping: NpmBasedPackageManager(uniqueName: "yarn2-real", isReal: true, lazyContextSetupCommand: lazyContextSetupCommand, solveCommand: solveCommand),
            sleepTime: 60))
}
