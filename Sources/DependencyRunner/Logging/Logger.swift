import ColorizeSwift
import Foundation

struct Logger {
    let renamer: PackageRenamer
    
    func log(startPackageManager managerName: String) {
        print("Starting execution with package manager: \(managerName.bold())".underline())
    }
    
    func log(createContext ctx: ContextVar) {
        let logStr = "\(ctx) <- freshContext()"
        print("    \((logStr + " ... ").dim())", terminator: "")
        fflush(__stdoutp)
    }
    func log(opExecution op: EcosystemOp) {
        let logStr: String
        switch op {
        case let .publish(package: p, version: v, dependencies: deps):
            let newP = renamer.decode(p)
            let newDeps = deps.map { DependencyExpr(packageToDependOn: renamer.decode($0.packageToDependOn), constraint: $0.constraint) }
            logStr = "publish(\(newP), \(v), \(newDeps))"
        case let .yank(package: p, version: v):
            logStr = "yank(\(renamer.decode(p)), \(v))"
        case let .solve(inContext: ctx, constraints: deps):
            let newDeps = deps.map { DependencyExpr(packageToDependOn: renamer.decode($0.packageToDependOn), constraint: $0.constraint) }
            logStr = "\(ctx) <- solve(\(newDeps))"
        }
        
        print("    \((logStr + " ... ").bold())", terminator: "")
        fflush(__stdoutp)
    }
    
    func logOpFailure() {
        print(" 🚫")
    }
    
    func logOpSuccess() {
        print(" ✅")
    }
}
