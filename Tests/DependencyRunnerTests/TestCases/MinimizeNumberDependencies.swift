import XCTest
@testable import DependencyRunner

final class MinimizeNumberDependencies: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func program_testObviousSingleResolutionPrerelease(p: PackageManager) -> SolveResult {
        p.publish(package: "b", version: "0.0.1", dependencies: [])
        p.publish(package: "b", version: "0.0.2", dependencies: [])
        p.publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"))])
        let ctx = p.makeSolveContext()
        return ctx([DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    }

    func testObviousSingleResolutionPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testObviousSingleResolutionPrerelease)
        
        let correctResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "0.0.1", children: [
                ResolvedPackage(package: "b", version: "0.0.2", children: [])]),
            ResolvedPackage(package: "b", version: "0.0.2", children: [])]))
        
        XCTAssertEqual(resultGroups[correctResult], ["npm", "yarn1", "yarn2", "pip", "cargo"])
    }
    
    
    func program_testObviousSingleResolution(p: PackageManager) -> SolveResult {
        p.publish(package: "b", version: "1.0.1", dependencies: [])
        p.publish(package: "b", version: "1.0.2", dependencies: [])
        p.publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.2"))])
        let ctx = p.makeSolveContext()
        return ctx([DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    }

    func testObviousSingleResolution() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testObviousSingleResolution)
        
        let correctResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "1.0.1", children: [
                ResolvedPackage(package: "b", version: "1.0.2", children: [])]),
            ResolvedPackage(package: "b", version: "1.0.2", children: [])]))
        
        XCTAssertEqual(resultGroups[correctResult], ["npm", "yarn1", "yarn2", "pip", "cargo"])
    }

    static var allTests: [(String, (MinimizeNumberDependencies) -> () -> ())] = [
        ("testObviousSingleResolutionPrerelease", testObviousSingleResolutionPrerelease),
        ("testObviousSingleResolution", testObviousSingleResolution),
    ]
}
