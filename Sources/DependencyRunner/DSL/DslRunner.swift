
//struct EcosystemStore: Equatable, Hashable {
//    let contextResults: [ContextVar : SolveResult?]
//}
//
//func dictionaryOfNils<K, V>(forKeys: [K]) -> [K : V?] {
//    Dictionary(uniqueKeysWithValues: forKeys.map { ($0, nil) })
//}
import Foundation

enum ExecutionError: Error, Equatable, Hashable {
    case publishError(error: PublishError)
    case yankError(error: YankError)
}

typealias ExecutionResult = Result<[SolveResult], ExecutionError>

extension EcosystemProgram {
    private func runOps(underPackageManager p: PackageManager, logger: Logger) -> ExecutionResult {
        logger.log(startPackageManager: p.uniqueName)
        
//        var contextResults: [ContextVar : SolveResult?] = Dictionary(uniqueKeysWithValues: self.declaredContexts.map { ($0, nil) })
        
        var allResults: [SolveResult] = []
        
        let contexts: [ContextVar : SolveContext] = Dictionary(uniqueKeysWithValues: self.declaredContexts.map { ctx in
            logger.log(createContext: ctx)
            let result = (ctx, p.makeSolveContext())
            logger.logOpSuccess()
            return result
        })
        
        for op in self.ops {
            logger.log(opExecution: op)
            switch op {
            case let .publish(package: package, version: v, dependencies: deps):
                switch p.publish(package: package, version: v, dependencies: deps) {
                case .failure(let err):
                    logger.logOpFailure()
                    return .failure(.publishError(error: err))
                default: break
                }
            case let .yank(package: package, version: v):
                switch p.yank(package: package, version: v) {
                case .failure(let err):
                    logger.logOpFailure()
                    return .failure(.yankError(error: err))
                default: break
                }
            case let .solve(inContext: ctxVar, constraints: constraints):
                let result = contexts[ctxVar]!(constraints)
//                contextResults[ctxVar] = result
                allResults.append(result)
            }
            logger.logOpSuccess()
        }
        
        
        return .success(allResults)
        
//        return ProgramResult(solveResults: allResults, ecosystemStore: EcosystemStore(contextResults: contextResults))
        
    }
    func run(underPackageManager p: PackageManager) -> Result<[SolveResult], ExecutionError> {
        let renamer = buildUniquePackageRenaming(self)
        let transformedProg = self.mapPackageNames(renamer.encode)
//        let transformedProg = self
        
        p.startup()
        defer {
            p.shutdown()
        }
        
        let logger = Logger(renamer: renamer)
        
        let result = transformedProg.runOps(underPackageManager: p, logger: logger)
        let decodedResult = result.map { $0.map { $0.map { $0.mapPackageNames(renamer.decode) } } }
        
        return decodedResult
//        return result
    }
}
