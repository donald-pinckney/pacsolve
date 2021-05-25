import ShellOut
import Foundation

//protocol SolveContext {
//    func solve(dependencies: [DependencyExpr]) -> SolveResult
//}

struct PublishError: Error, Equatable, Hashable {
    let message: String
}

struct YankError: Error, Equatable, Hashable {
    let message: String
}

struct UnsupportedConstraintError: Error {
    let constraint: ConstraintExpr
}


typealias SolveResult<T: Hashable> = Result<SolutionTree<T>, SolveError>
typealias PublishResult = Result<(), PublishError>
typealias YankResult = Result<(), YankError>

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success(let succ):
            return "success(\(succ))"
        case .failure(let err):
            return "failure(\(err))"
        }
    }
}


typealias SolveContext = ([DependencyExpr]) -> SolveResult<Int>

protocol InternalPackageManager {
    var uniqueName: String { get }
    var shouldRenameVars: Bool { get }
    
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) -> PublishResult
    func yank(package: Package, version: Version) -> YankResult
    
    func makeSolveContext() -> SolveContext
    
    func startup()
    func shutdown()
}



struct LocalPackageManager: PackageManager {
    typealias DataType = Int
    let pm: InternalPackageManager
    
    var uniqueName: String {
        pm.uniqueName
    }
    
    func run(program prog: EcosystemProgram) -> Result<[SolutionTree<Int>], ExecutionError> {
        let renamer: PackageRenamer
        if pm.shouldRenameVars {
            renamer = buildUniquePackageRenaming(prog)
        } else {
            renamer = identityRenaming()
        }
        
        let transformedProg = prog.mapPackageNames(renamer.encode)

        pm.startup()
        defer {
            pm.shutdown()
        }

        let logger = Logger(renamer: renamer)

        let result = self.runOps(prog: transformedProg, logger: logger)
        let decodedResult = result.map { $0.map { $0.mapPackageNames(renamer.decode) } }

        return decodedResult
    }
    
    
    
    
    
    private func runOps(prog: EcosystemProgram, logger: Logger) -> ExecutionResult<Int> {
        logger.log(startPackageManager: uniqueName)


        var allResults: [SolutionTree<Int>] = []

        let contexts: [ContextVar : SolveContext] = Dictionary(uniqueKeysWithValues: prog.declaredContexts.map { ctx in
            logger.log(createContext: ctx)
            let result = (ctx, pm.makeSolveContext())
            logger.logOpSuccess()
            return result
        })

        for op in prog.ops {
            logger.log(opExecution: op)
            switch op {
            case let .publish(package: package, version: v, dependencies: deps):
                switch pm.publish(package: package, version: v, dependencies: deps) {
                case .failure(let err):
                    logger.logOpFailure()
                    return .failure(.publishError(error: err))
                default: break
                }
            case let .yank(package: package, version: v):
                switch pm.yank(package: package, version: v) {
                case .failure(let err):
                    logger.logOpFailure()
                    return .failure(.yankError(error: err))
                default: break
                }
            case let .solve(inContext: ctxVar, constraints: constraints):
                let result = contexts[ctxVar]!(constraints)
                switch result {
                case .failure(let err):
                    logger.logOpFailure()
                    return .failure(.solveError(error: err))
                case .success(let sol):
                    allResults.append(sol)
                }
            }
            logger.logOpSuccess()
        }


        return .success(allResults)
    }
}
