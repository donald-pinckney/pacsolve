import ShellOut

private class PipImpl {
    let uniqueName: String
    let isReal: Bool
    let dirManager: GenDirManager
    var templateManager: TemplateManager
    
    init(uniqueName: String, isReal: Bool) {
        self.uniqueName = uniqueName
        self.isReal = isReal
        self.dirManager = GenDirManager(baseName: uniqueName)
        self.templateManager = TemplateManager(templateName: uniqueName)
        self.templateManager.delegate = self
    }
}

extension PipImpl : PackageManager {
    private func buildToRegistry(inDirectory srcDir: String) -> PublishResult {
        try! shellOut(to: "python3.9 setup.py bdist_wheel", at: srcDir)
        
        do {
            if isReal {
                try shellOut(to: "twine upload --repository testpypi --username __token__ --password pypi-AgENdGVzdC5weXBpLm9yZwIkNDdlMjE3YTQtMDNmNy00NzQ5LWJlMmItYTQwYTQyYTQ3OTNlAAIleyJwZXJtaXNzaW9ucyI6ICJ1c2VyIiwgInZlcnNpb24iOiAxfQAABiAFgR8lbkJbvmFLagUxJ_OJeXEpZEcfAQXFjZSFMYzaag dist/*", at: srcDir)
            } else {
                try shellOut(to: "cp \(srcDir)dist/*.whl \(self.dirManager.getRegistryDirectory().relative)")
            }
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
        
        let makeVenvCommand =
        """
            python3.9 -m venv --upgrade-deps env
        """
        
        try! shellOut(to: makeVenvCommand, at: contextDir)
            
        let context = PipSolveContext(contextDir: contextDir, templateManager: self.templateManager)
        
        return context.solve
    }
    
    func startup() {}
    func shutdown() {}
}

class PipSolveContext {
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
            return .failure(SolveError(message: "\(error)"))
        }
    }
}

extension PipImpl : TemplateManagerDelegate {
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


func Pip() -> PackageManager {
    PipImpl(uniqueName: "pip", isReal: false)
}

func PipReal() -> PackageManager {
    WaitForUpdateManager(wrapping: PipImpl(uniqueName: "pip-real", isReal: true), sleepTime: 60)
}
