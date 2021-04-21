import XCTest
@testable import DependencyRunner

final class MaximizeVersionNumbers: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func program_testAnyVersionMax(p: PackageManager) -> SolveResult {
        p.publish(package: "a", version: "0.0.1", dependencies: [])
        p.publish(package: "a", version: "0.0.2", dependencies: [])
        p.publish(package: "a", version: "0.1.0", dependencies: [])
        p.publish(package: "a", version: "0.1.1", dependencies: [])
        p.publish(package: "a", version: "0.1.2", dependencies: [])
        p.publish(package: "a", version: "1.0.0", dependencies: [])
        p.publish(package: "a", version: "1.0.1", dependencies: [])
        p.publish(package: "a", version: "2.0.0", dependencies: [])
        p.publish(package: "a", version: "2.0.1", dependencies: [])
        p.publish(package: "a", version: "2.1.0", dependencies: [])
        
        let ctx = p.makeSolveContext()
        return ctx([DependencyExpr(packageToDependOn: "a", constraint: .any)])
    }

    func testAnyVersionMax() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testAnyVersionMax)
        let correctResult = SolveResult.solveOk(SolutionTree(children: [ResolvedPackage(package: "a", version: "2.1.0", children: [])]))
        XCTAssertEqual(resultGroups[correctResult], ["npm", "yarn1", "yarn2", "pip", "cargo"])
    }

    static var allTests: [(String, (MaximizeVersionNumbers) -> () -> ())] = [
        ("testAnyVersionMax", testAnyVersionMax),
    ]
}
