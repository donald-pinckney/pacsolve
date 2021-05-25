import XCTest
@testable import DependencyRunner

final class MinimizeNumberDependencies: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    

    func testObviousSingleResolutionPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "ObviousSingleResolutionPre")
        
        let correctResult = ExecutionResult.success([
            SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", data: 0 as AnyHashable, children: [
                    ResolvedPackage(package: "b", version: "0.0.2", data: 0 as AnyHashable, children: [])]),
                ResolvedPackage(package: "b", version: "0.0.2", data: 1 as AnyHashable, children: [])])
        ])
        
        XCTAssertEqual(resultGroups[correctResult], npmNames().union(yarn1Names()).union(yarn2Names()).union(cargoNames()).union(pipNames()))
    }
    
    

    func testObviousSingleResolution() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "ObviousSingleResolution")

        let correctResult = ExecutionResult.success([
            SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", data: 0 as AnyHashable, children: [
                    ResolvedPackage(package: "b", version: "1.0.2", data: 0 as AnyHashable, children: [])]),
                ResolvedPackage(package: "b", version: "1.0.2", data: 1 as AnyHashable, children: [])
            ])
        ])
        
        XCTAssertEqual(resultGroups[correctResult], npmNames().union(yarn1Names()).union(yarn2Names()).union(cargoNames()).union(pipNames()))
    }

    static var allTests: [(String, (MinimizeNumberDependencies) -> () -> ())] = [
        ("testObviousSingleResolutionPrerelease", testObviousSingleResolutionPrerelease),
        ("testObviousSingleResolution", testObviousSingleResolution),
    ]
}
