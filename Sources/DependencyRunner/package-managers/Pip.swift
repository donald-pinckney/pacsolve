import ShellOut

class Pip {
    let dirManager = GenDirManager(baseName: "pip")
    var templateManager = TemplateManager(templateName: "pip")
    
    init() {
        self.templateManager.delegate = self
    }
}

extension Pip : PackageManager {
    typealias TheSolveContext = PipSolveContext

    private func buildToRegistry(inDirectory srcDir: String) {
        try! shellOut(to: "python3.9 setup.py bdist_wheel", at: srcDir)
        try! shellOut(to: "cp \(srcDir)dist/*.whl \(self.dirManager.getRegistryDirectory())")
    }
        
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) {
        let sourceDir = dirManager.generateUniqueSourceDirectory(forPackage: package, version: version)
                
        templateManager.instantiatePackageTemplate(intoDirectory: sourceDir, package: package, version: version, dependencies: dependencies)
        
        buildToRegistry(inDirectory: sourceDir)
    }
    
    func yank(package: Package, version: Version) {
        fatalError("Unimplemented")
    }
    
    func makeSolveContext() -> PipSolveContext {
        let contextDir = dirManager.newContextDirectory()
        
        let makeVenvCommand =
        """
            python3.9 -m venv --upgrade-deps env
        """
        
        try! shellOut(to: makeVenvCommand, at: contextDir)
            
        return PipSolveContext(contextDir: contextDir, templateManager: self.templateManager)
    }    
}

class PipSolveContext : SolveContext {
    let contextDir: String
    let templateManager: TemplateManager
    
    init(contextDir: String, templateManager: TemplateManager) {
        self.contextDir = contextDir
        self.templateManager = templateManager
    }
    
    func solve(dependencies: [DependencyExpr]) -> SolveResult {
        templateManager.instantiatePackageTemplate(intoDirectory: contextDir, package: "context", version: "0.0.1", dependencies: dependencies)
        
        let solveCommand =
        """
            source env/bin/activate;
            pip install -q -r requirements.txt &&
            python main.py &&
            deactivate
        """
        
        do {
            let output = try shellOut(to: solveCommand, at: self.contextDir)
            var parser = SolutionTreeParser(toParse: output)
            return parser.parseSolutionTree()
        } catch {
            return .solveError("\(error)")
        }
    }
}

extension Pip : TemplateManagerDelegate {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
        [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.description,
            "$DEPENDENCIES_COMMA_SEP" : dependencies.map { $0.pipFormat().quoted() }.joined(separator: ", \n"),
            "$DEPENDENCIES_LINE_SEP" : dependencies.map { $0.pipFormat() }.joined(separator: "\n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import \($0.packageToDependOn)" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
    }
}

extension ConstraintExpr {
    func pipFormat() -> String {
        switch self {
        case .any:
            return ""
        case .exactly(let v):
            return "==\(v)"
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
    func pipFormat() -> String {
        "\(self.packageToDependOn)\(self.constraint.pipFormat())"
    }
}
