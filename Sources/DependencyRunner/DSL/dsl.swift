enum ConstraintExpr {
    case any
    case exactly(Version)
}

struct DependencyExpr {
    let packageToDependOn: Package
    let constraint: ConstraintExpr
}

//struct EcosystemNode {
//    let package: Package
//    let version: Version
//    let dependencies: [DependencyExpr]
//}

typealias ContextVar = String

enum EcosystemOp {
    case publish(package: Package, version: Version, dependencies: [DependencyExpr])
    case yank(package: Package, version: Version)
    case solve(inContext: ContextVar, constraints: [DependencyExpr])
}

struct EcosystemProgram {
    let declaredContexts: Set<ContextVar>
    let ops: [EcosystemOp]
}

