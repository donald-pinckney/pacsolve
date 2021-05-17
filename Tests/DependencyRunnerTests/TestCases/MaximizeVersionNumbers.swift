import XCTest
@testable import DependencyRunner

final class MaximizeVersionNumbers: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func testAnyVersionMax() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "AnyVersionMax")
        let correctResult = ExecutionResult.success([
            SolveResult.success(SolutionTree(children: [ResolvedPackage(package: "a", version: "2.1.0", data: 0, children: [])]))
        ])
        XCTAssertEqual(resultGroups[correctResult], npmNames().union(yarn1Names()).union(yarn2Names()).union(cargoNames()).union(pipNames()))
    }

    static var allTests: [(String, (MaximizeVersionNumbers) -> () -> ())] = [
        ("testAnyVersionMax", testAnyVersionMax),
    ]
}
