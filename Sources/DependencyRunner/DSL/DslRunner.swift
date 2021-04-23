
//struct EcosystemStore: Equatable, Hashable {
//    let contextResults: [ContextVar : SolveResult?]
//}
//
//func dictionaryOfNils<K, V>(forKeys: [K]) -> [K : V?] {
//    Dictionary(uniqueKeysWithValues: forKeys.map { ($0, nil) })
//}

extension EcosystemProgram {
    private func runOps(underPackageManager p: PackageManager) -> [SolveResult] {
//        var contextResults: [ContextVar : SolveResult?] = Dictionary(uniqueKeysWithValues: self.declaredContexts.map { ($0, nil) })
        
        var allResults: [SolveResult] = []
        
        let contexts: [ContextVar : SolveContext] = Dictionary(uniqueKeysWithValues: self.declaredContexts.map { ($0, p.makeSolveContext()) })
        
        for op in self.ops {
            switch op {
            case let .publish(package: package, version: v, dependencies: deps):
                p.publish(package: package, version: v, dependencies: deps)
            case let .yank(package: package, version: v):
                p.yank(package: package, version: v)
            case let .solve(inContext: ctxVar, constraints: constraints):
                let result = contexts[ctxVar]!(constraints)
//                contextResults[ctxVar] = result
                allResults.append(result)
            }
        }
        
        
        return allResults
        
//        return ProgramResult(solveResults: allResults, ecosystemStore: EcosystemStore(contextResults: contextResults))
        
    }
    func run(underPackageManager p: PackageManager) -> [SolveResult] {
        let renamer = buildUniquePackageRenaming(self)
        let transformedProg = self.mapPackageNames(renamer.encode)
//        let transformedProg = self
        
        p.startup()
        defer {
            p.shutdown()
        }
        
        let result = transformedProg.runOps(underPackageManager: p)
        let decodedResult = result.map { $0.mapOk { $0.mapPackageNames(renamer.decode) } }
        
        return decodedResult
//        return result
    }
}
