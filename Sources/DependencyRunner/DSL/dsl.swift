indirect enum ConstraintExpr: CustomStringConvertible { // npm                      cargo                   pip
                                                        // ------------             ------------            ------------
    case exactly(Version)                               // 1.2.3                    =1.2.3                  ==1.2.3
    case geq(Version)                                   // >=1.2.3                  >=1.2.3                 >=1.2.3
    case gt(Version)                                    // >1.2.3                   >1.2.3                  >1.2.3
    case leq(Version)                                   // <=1.2.3                  <=1.2.3                 <=1.2.3
    case lt(Version)                                    // <1.2.3                   <1.2.3                  <1.2.3
    case caret(Version)                                 // ^1.2.3                   ^1.2.3          [3]         n/a
    case tilde(Version)                                 // ~1.2.3                   ~1.2.3                  ~=1.2.3
    case and(ConstraintExpr, ConstraintExpr)            // >=1.0.2 <2.1.2           >=1.0.2, <2.1.2         >=1.0.2, <2.1.2
    case or(ConstraintExpr, ConstraintExpr)             // >=1.0.2 || <2.1.2            n/a                     n/a
    case wildcardBug(Int, Int)                          // 1.2.x                    1.2.*                   ==1.2.*
    case wildcardMinor(Int)                             // 1.x                      1.*                     ==1.*
    case wildcardMajor                                  // *                        *                       "" (empty string)
    case not(ConstraintExpr)                            //      n/a                     n/a                 !=1.2.3             [5]
    
    // [3]: Also 1.2.3
    // [5]: You can also do e.g. !=1.2.*. Doesn't appear that you can use != as a general not
    
    // Npm reference: https://docs.npmjs.com/cli/v7/configuring-npm/package-json#dependencies
    // Cargo reference: https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html
    // Pip reference: https://www.python.org/dev/peps/pep-0440/#version-specifiers
    
    var description: String {
        switch self {
        case .wildcardMajor: return "*"
        case let .exactly(v): return "==\(v)"
        case let .geq(v): return ">=\(v)"
        case let .gt(v): return ">\(v)"
        case let .leq(v): return "<=\(v)"
        case let .lt(v): return "<\(v)"
        case let .caret(v): return "^\(v)"
        case let .tilde(v): return "~\(v)"
        case let .and(c1, c2): return "(\(c1)) & (\(c2))"
        case let .or(c1, c2): return "(\(c1)) | (\(c2))"
        case let .wildcardBug(major, minor): return "==\(major).\(minor).*"
        case let .wildcardMinor(major): return "==\(major).*"
        case let .not(c): return "!(\(c))"
        }
    }
    
    static var any: ConstraintExpr {
        .wildcardMajor
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

