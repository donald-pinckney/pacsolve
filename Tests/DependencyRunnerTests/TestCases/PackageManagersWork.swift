import XCTest
@testable import DependencyRunner

final class PackageManagersWork: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    let testEcosystem = Ecosystem([
        "m": [
            "0.0.1": [DependencyExpr(packageToDependOn: "a", constraint: .any)],
        ],
        "a": [
            "0.0.1": [],
        ],
    ])
    
    let correctResult = SolutionTree(package: "m", version: "0.0.1", children: [SolutionTree(package: "a", version: "0.0.1", children: [])])
    
    
    func testPipWorks() {
        let result = Pip().solve(testEcosystem, forRootPackage: "m", version: "0.0.1")
        let tree = assertOk(result: result)
        XCTAssertEqual(tree, correctResult)
    }

    func testNpmWorks() {
        let result = Npm().solve(testEcosystem, forRootPackage: "m", version: "0.0.1")
        let tree = assertOk(result: result)
        XCTAssertEqual(tree, correctResult)
    }

    func testYarn1Works() {
        let result = Yarn1().solve(testEcosystem, forRootPackage: "m", version: "0.0.1")
        let tree = assertOk(result: result)
        XCTAssertEqual(tree, correctResult)
    }

    func testYarn2Works() {
        let result = Yarn2().solve(testEcosystem, forRootPackage: "m", version: "0.0.1")
        let tree = assertOk(result: result)
        XCTAssertEqual(tree, correctResult)
    }

    func testCargoWorks() {
        let result = Cargo().solve(testEcosystem, forRootPackage: "m", version: "0.0.1")
        let tree = assertOk(result: result)
        XCTAssertEqual(tree, correctResult)
    }


    static var allTests = [
        ("testPipWorks", testPipWorks),
        ("testNpmWorks", testNpmWorks),
        ("testYarn1Works", testYarn1Works),
        ("testYarn2Works", testYarn2Works),
        ("testCargoWorks", testCargoWorks),
    ]
}
