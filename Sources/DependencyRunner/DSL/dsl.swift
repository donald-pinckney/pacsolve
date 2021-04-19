enum ConstraintExpr {
    case any
    case exactly(Version)
}

struct DependencyExpr {
    let packageToDependOn: Package
    let constraint: ConstraintExpr
}

struct EcosystemNode {
    let package: Package
    let version: Version
    let dependencies: [DependencyExpr]
}

//struct Ecosystem {
//    let nodes: [EcosystemNode]
//    init(_ ecosystemDict: [Package : [Version : [DependencyExpr]]]) {
//        var tmpNodes: [EcosystemNode] = []
//        
//        for (pkg, pkgDict) in ecosystemDict {
//            for (v, deps) in pkgDict.sorted(by: { $0.key < $1.key }) {
//                tmpNodes.append(EcosystemNode(package: pkg, version: v, dependencies: deps))
//            }
//        }
//        
//        nodes = tmpNodes
//    }
//}
//
//extension Ecosystem: Sequence {
//    typealias Iterator = AnyIterator<EcosystemNode>
//    
//    func makeIterator() -> Iterator {
//        var it = nodes.makeIterator()
//        return AnyIterator {
//            return it.next()
//        }
//    }
//}
//
//extension Ecosystem: Collection {
//    typealias Index = Int
//    var startIndex: Int {
//        nodes.startIndex
//    }
//    var endIndex: Int {
//        nodes.endIndex
//    }
//    subscript(position: Int) -> Iterator.Element {
//        precondition(indices.contains(position), "out of bounds")
//        return nodes[position]
//    }
//    func index(after i: Int) -> Int {
//        nodes.index(after: i)
//    }
//}
//
//extension PackageManager {
//    func solve(_ ecosystem: Ecosystem, forRootPackage root: Package, version: Version) -> SolveResult {
//        self.generate(ecosystem: ecosystem)
//        return solve(package: root, version: version)
//    }
//}
