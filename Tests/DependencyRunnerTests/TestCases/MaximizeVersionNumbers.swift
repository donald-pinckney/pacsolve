import XCTest
@testable import DependencyRunner

final class MaximizeVersionNumbers: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func testAnyVersionMax() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "AnyVersionMax")
        let correctResult = [
            SolveResult.solveOk(SolutionTree(children: [ResolvedPackage(package: "a", version: "2.1.0", children: [])]))
        ]
        XCTAssertEqual(resultGroups[correctResult], npmNames() + yarn1Names() + yarn2Names() + pipNames() + cargoNames())
    }

    static var allTests: [(String, (MaximizeVersionNumbers) -> () -> ())] = [
        ("testAnyVersionMax", testAnyVersionMax),
    ]
}
