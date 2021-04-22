
struct EcosystemStore {
    let contextResults: [ContextVar : SolveResult?]
}

func dictionaryOfNils<K, V>(forKeys: [K]) -> [K : V?] {
    Dictionary(uniqueKeysWithValues: forKeys.map { ($0, nil) })
}

extension EcosystemProgram {
    func run(underPackageManager p: PackageManager) -> ([SolveResult], EcosystemStore) {
        p.startup()

        var contextResults: [ContextVar : SolveResult?] = Dictionary(uniqueKeysWithValues: self.declaredContexts.map { ($0, nil) })
        
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
                contextResults[ctxVar] = result
                allResults.append(result)
            }
        }
        
        p.shutdown()
        
        return (allResults, EcosystemStore(contextResults: contextResults))
    }
}
