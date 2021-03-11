import Files
import ShellOut


struct Pip : PackageManagerWithRegistry {
    let name = "pip"
    var genBinPathDir: String {
        get {
            "\(self.rootPathDir)generated/\(self.name)/bin/"
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
            "$DIST_DIR" : self.genBinPathDir,
            "$DEPENDENCIES_LINE_SEP" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, pkgDir: String) {
//        print("Building: \(pkgDir)")
        try! shellOut(to: "python3 setup.py bdist_wheel", at: pkgDir)
        try! shellOut(to: "cp \(pkgDir)dist/*.whl \(self.genBinPathDir)")
    }
    
    
    func solveCommand(forMainPath mainPath: String) -> SolveCommand {
        let solver = SolveCommand(directory: mainPath, command: """
            rm -rf env;
            python3 -m venv --upgrade-deps env;
            source env/bin/activate;
            pip3 install -q -r requirements.txt &&
            python3 main.py &&
            deactivate
        """, packageManager: self)
        
        return solver
    }
    
    func cleanup() {

    }
}
