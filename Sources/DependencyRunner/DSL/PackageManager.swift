import ShellOut
import Foundation

//protocol SolveContext {
//    func solve(dependencies: [DependencyExpr]) -> SolveResult
//}

struct PublishError: Error {
    let message: String
}

struct YankError: Error {
    let message: String
}

typealias SolveResult = Result<SolutionTree, SolveError>
typealias PublishResult = Result<(), PublishError>
typealias YankResult = Result<(), YankError>


typealias SolveContext = ([DependencyExpr]) -> SolveResult

protocol PackageManager {
    var uniqueName: String { get }
    
    func publish(package: Package, version: Version, dependencies: [DependencyExpr])
    func yank(package: Package, version: Version)
    
    func makeSolveContext() -> SolveContext
    
    func startup()
    func shutdown()
}
