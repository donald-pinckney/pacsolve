import ShellOut
import Foundation

//protocol SolveContext {
//    func solve(dependencies: [DependencyExpr]) -> SolveResult
//}

typealias SolveContext = ([DependencyExpr]) -> SolveResult

protocol PackageManager {
    var uniqueName: String { get }
    
    func publish(package: Package, version: Version, dependencies: [DependencyExpr])
    func yank(package: Package, version: Version)
    
    func makeSolveContext() -> SolveContext
    
    func startup()
    func shutdown()
}
