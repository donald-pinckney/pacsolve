indirect enum ConstraintExpr: CustomStringConvertible {
                                                        // npm                      cargo                   pip
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

extension ConstraintExpr: Codable {
    // Follows: https://www.objc.io/blog/2018/01/23/codable-enums/
    
    enum CodingKeys: CodingKey {
        case type_exactly
        case type_geq
        case type_gt
        case type_leq
        case type_lt
        case type_caret
        case type_tilde
        case type_and
        case type_or
        case type_wildcardBug
        case type_wildcardMinor
        case type_wildcardMajor
        case type_not
    }
    
    enum LeftRightKeys: CodingKey {
        case left
        case right
    }
    
    enum MajorMinorKeys: CodingKey {
        case major
        case minor
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .exactly(v): try container.encode(v, forKey: .type_exactly)
        case let .geq(v): try container.encode(v, forKey: .type_geq)
        case let .gt(v): try container.encode(v, forKey: .type_gt)
        case let .leq(v): try container.encode(v, forKey: .type_leq)
        case let .lt(v): try container.encode(v, forKey: .type_lt)
        case let .caret(v): try container.encode(v, forKey: .type_caret)
        case let .tilde(v): try container.encode(v, forKey: .type_tilde)
        case let .and(c1, c2):
            var args = container.nestedContainer(keyedBy: LeftRightKeys.self, forKey: .type_and)
            try args.encode(c1, forKey: .left)
            try args.encode(c2, forKey: .right)
        case let .or(c1, c2):
            var args = container.nestedContainer(keyedBy: LeftRightKeys.self, forKey: .type_or)
            try args.encode(c1, forKey: .left)
            try args.encode(c2, forKey: .right)
        case let .wildcardBug(major, minor):
            var args = container.nestedContainer(keyedBy: MajorMinorKeys.self, forKey: .type_wildcardBug)
            try args.encode(major, forKey: .major)
            try args.encode(minor, forKey: .minor)
        case let .wildcardMinor(major): try container.encode(major, forKey: .type_wildcardMinor)
        case .wildcardMajor: try container.encodeNil(forKey: .type_wildcardMajor)
        case let .not(c): try container.encode(c, forKey: .type_not)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = container.allKeys
        if keys.count != 1 {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected exactly 1 key when decoding ConstraintExpr"))
        }
        
        let k = keys[0]
        switch k {
        case .type_exactly: self = .exactly(try container.decode(Version.self, forKey: k))
        case .type_geq: self = .geq(try container.decode(Version.self, forKey: k))
        case .type_gt: self = .gt(try container.decode(Version.self, forKey: k))
        case .type_leq: self = .leq(try container.decode(Version.self, forKey: k))
        case .type_lt: self = .lt(try container.decode(Version.self, forKey: k))
        case .type_caret: self = .caret(try container.decode(Version.self, forKey: k))
        case .type_tilde: self = .tilde(try container.decode(Version.self, forKey: k))
        case .type_and:
            let inner = try container.nestedContainer(keyedBy: LeftRightKeys.self, forKey: k)
            try self = .and(inner.decode(ConstraintExpr.self, forKey: .left), inner.decode(ConstraintExpr.self, forKey: .right))
        case .type_or:
            let inner = try container.nestedContainer(keyedBy: LeftRightKeys.self, forKey: k)
            try self = .or(inner.decode(ConstraintExpr.self, forKey: .left), inner.decode(ConstraintExpr.self, forKey: .right))
        case .type_wildcardBug:
            let inner = try container.nestedContainer(keyedBy: MajorMinorKeys.self, forKey: k)
            try self = .wildcardBug(inner.decode(Int.self, forKey: .major), inner.decode(Int.self, forKey: .minor))
        case .type_wildcardMinor: self = .wildcardMinor(try container.decode(Int.self, forKey: k))
        case .type_wildcardMajor:
            if !(try container.decodeNil(forKey: k)) {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [k], debugDescription: "Expected null value to be encoded"))
            }
            self = .wildcardMajor
        case .type_not: self = .not(try container.decode(ConstraintExpr.self, forKey: k))
        }
    }
}

struct DependencyExpr: CustomStringConvertible, Codable {
    let packageToDependOn: Package
    let constraint: ConstraintExpr
    
    var description: String {
        "\(packageToDependOn) \(constraint)"
    }
}

typealias ContextVar = String

enum EcosystemOp: Codable {
    case publish(package: Package, version: Version, dependencies: [DependencyExpr])
    case yank(package: Package, version: Version)
    case solve(inContext: ContextVar, constraints: [DependencyExpr])
    
    enum CodingKeys: CodingKey {
        case op_publish
        case op_yank
        case op_solve
    }
    
    enum InnerKeys: CodingKey {
        case package
        case version
        case dependencies
        case context
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .publish(package: p, version: v, dependencies: deps):
            var args = container.nestedContainer(keyedBy: InnerKeys.self, forKey: .op_publish)
            try args.encode(p, forKey: .package)
            try args.encode(v, forKey: .version)
            try args.encode(deps, forKey: .dependencies)
        case let .yank(package: p, version: v):
            var args = container.nestedContainer(keyedBy: InnerKeys.self, forKey: .op_yank)
            try args.encode(p, forKey: .package)
            try args.encode(v, forKey: .version)
        case let .solve(inContext: ctx, constraints: cs):
            var args = container.nestedContainer(keyedBy: InnerKeys.self, forKey: .op_solve)
            try args.encode(ctx, forKey: .context)
            try args.encode(cs, forKey: .dependencies)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = container.allKeys
        if keys.count != 1 {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected exactly 1 key when decoding EcosystemOp"))
        }
        
        let k = keys[0]
        switch k {
        case .op_publish:
            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
            try self = .publish(
                package: inner.decode(Package.self, forKey: .package),
                version: inner.decode(Version.self, forKey: .version),
                dependencies: inner.decode([DependencyExpr].self, forKey: .dependencies))
        case .op_yank:
            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
            try self = .yank(
                package: inner.decode(Package.self, forKey: .package),
                version: inner.decode(Version.self, forKey: .version))
        case .op_solve:
            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
            try self = .solve(
                inContext: inner.decode(ContextVar.self, forKey: .context),
                constraints: inner.decode([DependencyExpr].self, forKey: .dependencies))
        }
    }
}

struct EcosystemProgram: Codable {
    let declaredContexts: Set<ContextVar>
    let ops: [EcosystemOp]
}

