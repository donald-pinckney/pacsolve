import Foundation

class WaitForUpdateManager : PackageManager {
    let wrapped: PackageManager
    let sleepTime: UInt32
    var isDirty = false
    var uniqueName: String { wrapped.uniqueName}
    
    init(wrapping: PackageManager, sleepTime: UInt32) {
        self.wrapped = wrapping
        self.sleepTime = sleepTime
    }
    
    func waitIfDirty() {
        if isDirty {
            sleep(sleepTime)
            isDirty = false
        }
    }
    
    func setDirty() {
        isDirty = true
    }
    
    func publish(package: Package, version: Version, dependencies: [DependencyExpr]) -> PublishResult {
        setDirty()
        return wrapped.publish(package: package, version: version, dependencies: dependencies)
    }
    
    func yank(package: Package, version: Version) -> YankResult {
        setDirty()
        return wrapped.yank(package: package, version: version)
    }
    
    func makeSolveContext() -> SolveContext {
        let f = wrapped.makeSolveContext()
        return { constraints in
            self.waitIfDirty()
            return f(constraints)
        }
        
    }
    
    func startup() {
        wrapped.startup()
    }
    
    func shutdown() {
        wrapped.shutdown()
    }
    
}
