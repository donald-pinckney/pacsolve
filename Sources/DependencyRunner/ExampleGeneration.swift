import Foundation


func generatePackagesAndVersions(numPackages: Int, numVersions: Int) -> [String : [Version]] {
    let packages = (0..<numPackages).map { "p\($0)" }
    var result: [String : [Version]] = [:]
    for p in packages {
        var versions: Set<Version> = []
        let vBound = max(Int(pow(Double(numVersions), 1.0/3.0)), 2) + 2
        for _ in 0..<numVersions {
            while true {
                let v = Version(major: Int.random(in: 0..<vBound), minor: Int.random(in: 0..<vBound), bug: Int.random(in: 0..<vBound))
                if !versions.contains(v) {
                    versions.insert(v)
                    break
                }
            }
        }
        
        result[p] = Array(versions)
    }
    return result
}

func generateRandomExampleEmptyConstraints(numPackages: Int, numVersions: Int) -> EcosystemProgram {

    let pkgs = generatePackagesAndVersions(numPackages: numPackages, numVersions: numVersions)
    
    var ops: [EcosystemOp] = pkgs.flatMap { (p: String, vs: [Version]) in
        vs.map { v in
            return .publish(package: p, version: v, dependencies: [])
        }
    }
    
    
    ops.append(.solve(inContext: "ctx", constraints: []))
    
    return EcosystemProgram(declaredContexts: ["ctx"], ops: ops)
}


func generateRandomExampleAnyConstraints(numPackages: Int, numVersions: Int, numDeps: Int) -> EcosystemProgram {

    let pkgs = generatePackagesAndVersions(numPackages: numPackages, numVersions: numVersions)
    
    var ops: [EcosystemOp] = pkgs.flatMap { (p: String, vs: [Version]) in
        vs.map { v in
            let deps = (0..<numDeps).map { di in
                DependencyExpr(packageToDependOn: pkgs.keys.randomElement()!, constraint: .wildcardMajor)
            }
            return .publish(package: p, version: v, dependencies: deps)
        }
    }
    
    let deps = (0..<numDeps).map { di in
        DependencyExpr(packageToDependOn: pkgs.keys.randomElement()!, constraint: .wildcardMajor)
    }
    
    ops.append(.solve(inContext: "ctx", constraints: deps))
    
    return EcosystemProgram(declaredContexts: ["ctx"], ops: ops)
}
