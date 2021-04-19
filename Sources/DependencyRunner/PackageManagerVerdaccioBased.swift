import Files
import ShellOut

//protocol PackageManagerVerdaccioBased: PackageManagerWithRegistry {
//}
//
//extension PackageManagerVerdaccioBased {
//    var templateName: String { "verdaccio-based" }
//    
//    func initRegistry() {
//        startVerdaccio(name: uniqueName)
//    }
//    
//    func generatedDirectoryFor(package: Package, version: Version) -> String {
//        "\(genSourcesPathDir)\(package)/\(version.directoryName)/"
//    }
//    
//    
//    func constraintStr(_ c: ConstraintExpr) -> String {
//        switch c {
//        case .any:
//            return "*"
//        case .exactly(let v):
//            return "\(v.semverName)"
////        case .geq(let v):
////            return ">=\(v.semverName)"
////        case .gt(let v):
////            return ">\(v.semverName)"
////        case .leq(let v):
////            return "<=\(v.semverName)"
////        case .lt(let v):
////            return "<\(v.semverName)"
////        case .caret(let v):
////            return "^\(v.semverName)"
////        case .tilde(let v):
////            return "~\(v.semverName)"
//        }
//    }
//    
//    func formatDepenency(dep: DependencyExpr) -> String {
//        "\"\(dep.packageToDependOn)\": \"\(self.constraintStr(dep.constraint))\""
//    }
//    
//    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String] {
//        let substitutions: [String : String] = [
//            "$NAME_STRING" : package.name,
//            "$VERSION_STRING" : version.semverName,
//            "$DEPENDENCIES_JSON_FRAGMENT" : dependencies.map(self.formatDepenency).joined(separator: ", \n"),
//            "$DEPENDENCY_IMPORTS" : dependencies.map() { "const \($0.packageToDependOn) = require('\($0.packageToDependOn)');" }.joined(separator: "\n"),
//            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.packageToDependOn).dep_tree(indent + 1);" }.joined(separator: "\n    ")
//        ]
//        return substitutions
//    }
//    
//    func publish(package: Package, version: Version, pkgDir: String, dependencies: [DependencyExpr]) {
////        print("Publishing: \(pkgDir)")
//        try! shellOut(to: """
//            npm publish --registry http://localhost:4873
//        """, at: pkgDir)
//    }
//    
//    func finalizeRegistry(publishingData: [Package : [Version : ()]]) {}
//    
//    
//    func parseSingleTreePackageLine(line: Substring) -> (Int, Package, Version) {
//        cargoStyle_parseSingleTreePackageLine(line: line)
//    }
//    
//    func cleanup() {
//        killVerdaccio()
//    }
//}
