import Foundation

func getAllPackages(inDependencies: [DependencyExpr]) -> Set<Package> {
    Set(inDependencies.map { $0.packageToDependOn })
}

func getAllPackages(inProgram: EcosystemProgram) -> Set<Package> {
    var packages: Set<Package> = []
    
    for op in inProgram.ops {
        switch op {
        case .publish(package: let p, version: _, dependencies: let deps):
            packages.insert(p)
            packages.formUnion(getAllPackages(inDependencies: deps))
            for d in deps {
                packages.insert(d.packageToDependOn)
            }
        case .solve(inContext: _, constraints: let deps):
            packages.formUnion(getAllPackages(inDependencies: deps))
        case .yank(package: let p, version: _):
            packages.insert(p)
        }
    }
    
    return packages
}

private var uniqueNamingCounter: UInt64 = 0

func buildUniquePackageRenaming(_ program: EcosystemProgram) -> (encode: (Package) -> Package, decode: (Package) -> Package) {
    let currentPackages = Array(getAllPackages(inProgram: program))
    var encodeMap: [Package : Package] = [:]
    var decodeMap: [Package : Package] = [:]
    
    var time = Date().timeIntervalSinceReferenceDate.bitPattern
    
    for p in currentPackages {
        // Hash the nonce, system time, random number, and package name
        var d = Data(bytes: &time, count: MemoryLayout<UInt64>.size)
        d.append(Data(bytes: &uniqueNamingCounter, count: MemoryLayout<UInt64>.size))
        uniqueNamingCounter += 1
        var r = UInt64.random(in: UInt64.min...UInt64.max)
        d.append(Data(bytes: &r, count: MemoryLayout<UInt32>.size))
        d.append(p.name.data(using: .utf8)!)
        let sha = "a" + d.sha224().toHexString()
        
        
        let newP = Package(stringLiteral: sha)
        encodeMap[p] = newP
        assert(decodeMap[newP] == nil)
        decodeMap[newP] = p
    }
    
    return (encode: { encodeMap[$0]! }, decode: { decodeMap[$0]! })
}

extension EcosystemProgram {
    func mapPackageNames(_ f: (Package) -> Package) -> EcosystemProgram {
        let newOps = self.ops.map { op -> EcosystemOp in
            switch op {
            case let .publish(package: p, version: v, dependencies: deps):
                let newDeps = deps.map { DependencyExpr(packageToDependOn: f($0.packageToDependOn), constraint: $0.constraint) }
                return .publish(package: f(p), version: v, dependencies: newDeps)
            case let .yank(package: p, version: v):
                return .yank(package: f(p), version: v)
            case let .solve(inContext: cv, constraints: deps):
                let newDeps = deps.map { DependencyExpr(packageToDependOn: f($0.packageToDependOn), constraint: $0.constraint) }
                return .solve(inContext: cv, constraints: newDeps)
            }
        }
        
        return EcosystemProgram(declaredContexts: self.declaredContexts, ops: newOps)
    }
}
