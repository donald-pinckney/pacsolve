import Files
import ShellOut


struct Pip : PackageManagerWithRegistry {
    init() {}
    
    let name = "pip"
    var genBinPathDir: String {
        get {
            "generated/\(self.name)/bin/"
        }
    }
    
    func generatedDirectoryFor(package: Package, version: Version) -> String {
        "\(genSourcesPathDir)\(package)/\(version.directoryName)/"
    }
    
    func initRegistry() {
        mkdir_p(path: self.genBinPathDir)
    }
    
    
    func constraintStr(_ c: ConstraintExpr) -> String {
        switch c {
        case .any:
            return ""
        case .exactly(let v):
            return "==\(v.semverName)"
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
    
    func formatDepenency(dep: DependencyExpr) -> String {
        "\(dep.packageToDependOn)\(self.constraintStr(dep.constraint))"
    }
    
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
        let substitutions = [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.semverName,
            "$DEPENDENCIES_COMMA_SEP" : dependencies.map(self.formatDepenency).map {$0.quoted()}.joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import \($0.packageToDependOn)" }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, pkgDir: String, dependencies: [DependencyExpr]) {
        try! shellOut(to: "python3.9 setup.py bdist_wheel", at: pkgDir)
        try! shellOut(to: "cp \(pkgDir)dist/*.whl \(self.genBinPathDir)")
    }
    
    func finalizeRegistry(publishingData: [Package : [Version : ()]]) {}
    
    func solveCommand(package: Package, version: Version) -> String {
        """
            rm -rf env;
            python3.9 -m venv --upgrade-deps env;
            source env/bin/activate;
            pip install -q -r requirements.txt &&
            python main.py &&
            deactivate
        """
    }
    
    func parseSingleTreePackageLine(line: Substring) -> (Int, Package, Version) {
        cargoStyle_parseSingleTreePackageLine(line: line)
    }
    
    func cleanup() {

    }
}
