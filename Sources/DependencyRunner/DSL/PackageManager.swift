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
    
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) -> PublishResult
    func yank(package: Package, version: Version) -> YankResult
    
    func makeSolveContext() -> SolveContext
    
    func startup()
    func shutdown()
}
