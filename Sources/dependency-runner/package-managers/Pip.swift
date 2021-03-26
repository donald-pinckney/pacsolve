import Files
import ShellOut


struct Pip : PackageManagerWithRegistry {
    let name = "pip"
    var genBinPathDir: String {
        get {
            "generated/\(self.name)/bin/"
        }
    }
    
    func initRegistry() {
        mkdir_p(path: self.genBinPathDir)
    }
    
    
    func versionSpecStr(_ vs: VersionSpecifier) -> String {
        switch vs {
        case .any:
            return ""
        case .exactly(let v):
            return "==\(v.semverName)"
        case .geq(let v):
            return ">=\(v.semverName)"
        case .gt(let v):
            return ">\(v.semverName)"
        case .leq(let v):
            return "<=\(v.semverName)"
        case .lt(let v):
            return "<\(v.semverName)"
        case .caret(let v):
            return "^\(v.semverName)"
        case .tilde(let v):
            return "~\(v.semverName)"
        }
    }
    
    func formatDepenency(dep: (Package, VersionSpecifier)) -> String {
        "\(dep.0.name)\(self.versionSpecStr(dep.1))"
    }
    
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions = [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.semverName,
            "$DEPENDENCIES_COMMA_SEP" : dependencies.map(self.formatDepenency).map {$0.quoted()}.joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions = [
            "$DEPENDENCIES_LINE_SEP" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, pkgDir: String, dependencies: [(Package, VersionSpecifier)]) {
        try! shellOut(to: "python3.9 setup.py bdist_wheel", at: pkgDir)
        try! shellOut(to: "cp \(pkgDir)dist/*.whl \(self.genBinPathDir)")
    }
    
    func finalizeRegistry(publishingData: [Package : [Version : ()]]) {}
    
    func solveCommand(forMainPath mainPath: String) -> SolveCommand {
        let solver = SolveCommand(directory: mainPath, command: """
            rm -rf env;
            python3.9 -m venv --upgrade-deps env;
            source env/bin/activate;
            pip install -q -r requirements.txt &&
            python main.py &&
            deactivate
        """, packageManager: self)
        
        return solver
    }
    
    func parseSingleTreeMainLine(line: Substring) -> (Int, String) {
        cargoStyle_parseSingleTreeMainLine(line: line)
    }
    
    func parseSingleTreePackageLine(line: Substring) -> (Int, String, Version) {
        cargoStyle_parseSingleTreePackageLine(line: line)
    }
    
    func cleanup() {

    }
}
