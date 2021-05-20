enum ConstraintExpr: CustomStringConvertible {
    case any
    case exactly(Version)
    
    var description: String {
        switch self {
        case .any: return "*"
        case .exactly(let v): return "==\(v)"
        }
    }
}

struct DependencyExpr: CustomStringConvertible {
    let packageToDependOn: Package
    let constraint: ConstraintExpr
    
    var description: String {
        "\(packageToDependOn) \(constraint)"
    }
}

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

