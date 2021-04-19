import XCTest
@testable import DependencyRunner

final class MaximizeVersionNumbers: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

//    func testAnyVersionMax() {
//        let ecosystem = Ecosystem([
//            "m": [
//                "0.0.1": [DependencyExpr(packageToDependOn: "a", constraint: .any)],
//            ],
//            "a": [
//                "0.0.1": [], "0.0.2": [], "0.1.0": [], "0.1.1": [], "0.1.2": [], "1.0.0": [], "1.0.1": [], "2.0.0": [], "2.0.1": [], "2.1.0": []
//            ],
//        ])
//        
//        let resultGroups = solveEcosystemWithAllPackageManagers(ecosystem: ecosystem, forRootPackage: "m", version: "0.0.1")
//        assert(resultGroups, hasPartitions: [
//            ["npm", "yarn1", "yarn2", "pip", "cargo"],
//        ])
//    }

    static var allTests: [(String, (MaximizeVersionNumbers) -> () -> ())] = [
//        ("testAnyVersionMax", testAnyVersionMax),
    ]
}
