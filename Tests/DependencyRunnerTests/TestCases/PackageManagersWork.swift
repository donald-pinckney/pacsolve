import XCTest
@testable import DependencyRunner

final class PackageManagersWork: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    let correctResult = SolveResult.solveOk(SolutionTree(children: [ResolvedPackage(package: "a", version: "0.0.1", children: [])]))
    
    func programToTest<P: PackageManager>(packageManager: P) {
        packageManager.publish(package: "a", version: "0.0.1", dependencies: [])
        let ctx = packageManager.makeSolveContext()
        let result = ctx.solve(dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
        XCTAssertEqual(result, correctResult)
    }
    

    func testPipWorks() {
        programToTest(packageManager: Pip())
    }

    func testNpmWorks() {
        programToTest(packageManager: Npm())
    }

    func testYarn1Works() {
        programToTest(packageManager: Yarn1())
    }

    func testYarn2Works() {
        programToTest(packageManager: Yarn2())
    }

    func testCargoWorks() {
//        programToTest(packageManager: Cargo())
    }


    static var allTests: [(String, (PackageManagersWork) -> () -> ())] = [
        ("testPipWorks", testPipWorks),
        ("testNpmWorks", testNpmWorks),
        ("testYarn1Works", testYarn1Works),
        ("testYarn2Works", testYarn2Works),
        ("testCargoWorks", testCargoWorks),
    ]
}
