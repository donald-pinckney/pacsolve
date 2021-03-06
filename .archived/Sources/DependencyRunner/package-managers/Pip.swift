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

extension PipImpl : InternalPackageManager {
    var shouldRenameVars: Bool { isReal }
    
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
        if isReal {
            print("Please manually log in to https://test.pypi.org")
            print("Yank the package: \(package)")
            print("         version: \(version)")
            print("\nIf there was an error, type x. Press enter when done.")
            if let res = readLine() {
                if res.lowercased().contains("x") {
                    return .failure(YankError(message: "unknown"))
                }
            }
        } else {
            fatalError("Unimplemented")
        }
        
        return .success(())
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
    
    func solve(dependencies: [DependencyExpr]) -> SolveResult<Int> {
        do {
            try templateManager.instantiatePackageTemplate(intoDirectory: contextDir, package: "context", version: "0.0.1", dependencies: dependencies)
        } catch {
            return .failure(SolveError(message: "\(error)"))
        }
        
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
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) throws -> [String : String] {
        let depStrings = try dependencies.flatMap { try $0.pipFormat() }
        return [
            "$NAME_STRING" : package.description,
            "$VERSION_STRING" : version.description,
            "$DEPENDENCIES_COMMA_SEP" : depStrings.map { $0.quoted() }.joined(separator: ", \n"),
            "$DEPENDENCIES_LINE_SEP" : depStrings.joined(separator: "\n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import \($0.packageToDependOn)" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn).dep_tree(indent + 1, do_inc)" }.joined(separator: "\n    ")
        ]
    }
}

extension ConstraintExpr {
    func pipFormat() throws -> [String] {
        switch self {
            case .wildcardMajor:
                return [""]
            case .exactly(let v):
                return ["==\(v)"]
            case .geq(let v):
                return [">=\(v)"]
            case .gt(let v):
                return [">\(v)"]
            case .leq(let v):
                return ["<=\(v)"]
            case .lt(let v):
                return ["<\(v)"]
            case .caret(_):
                throw UnsupportedConstraintError(constraint: self)
            case .tilde(let v):
                return ["~=\(v)"]
            case let .and(c1, c2):
                return try c1.pipFormat() + c2.pipFormat()
            case .or(_, _):
                throw UnsupportedConstraintError(constraint: self)
            case let .wildcardBug(major, minor):
                return ["==\(major).\(minor).*"]
            case let .wildcardMinor(major):
                return ["==\(major).*"]
            case let .not(.exactly(v)):
                return ["!=\(v)"]
            case let .not(.wildcardBug(major, minor)):
                return ["!=\(major).\(minor).*"]
            case let .not(.wildcardMinor(major)):
                return ["!=\(major).*"]
            case .not(.wildcardMajor):
                return ["!=*"]
            case .not(_):
                throw UnsupportedConstraintError(constraint: self)
            case .other(let o):
                return [o]
        }
    }
}

extension DependencyExpr {
    func pipFormat() throws -> [String] {
        try self.constraint.pipFormat().map { "\(self.packageToDependOn)\($0)" }
    }
}


func Pip() -> LocalPackageManager {
    LocalPackageManager(pm: PipImpl(uniqueName: "pip", isReal: false))
}

func PipReal() -> LocalPackageManager {
    LocalPackageManager(pm: WaitForUpdateManager(wrapping: PipImpl(uniqueName: "pip-real", isReal: true), sleepTime: 60))
}
