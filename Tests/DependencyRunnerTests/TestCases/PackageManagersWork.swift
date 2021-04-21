import XCTest
@testable import DependencyRunner

final class PackageManagersWork: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    let aVersion1Result = SolveResult.solveOk(SolutionTree(children: [ResolvedPackage(package: "a", version: "0.0.1", children: [])]))
    let aVersion2Result = SolveResult.solveOk(SolutionTree(children: [ResolvedPackage(package: "a", version: "0.0.2", children: [])]))
    
    func programToTest(packageManager: PackageManager) {
        packageManager.publish(package: "a", version: "0.0.1", dependencies: [])
        
        let ctx1 = packageManager.makeSolveContext()
        let result1 = ctx1([DependencyExpr(packageToDependOn: "a", constraint: .any)])
        
        XCTAssertEqual(result1, aVersion1Result)

        packageManager.publish(package: "a", version: "0.0.2", dependencies: [])
        
        let ctx2 = packageManager.makeSolveContext()

        let result2 = ctx2([DependencyExpr(packageToDependOn: "a", constraint: .any)])
        XCTAssertEqual(result2, aVersion2Result)        
    }

    func testPipWorks() {
        runProgram(programToTest, underPackageManager: Pip())
    }

    func testNpmWorks() {
        runProgram(programToTest, underPackageManager: Npm())
    }

    func testYarn1Works() {
        runProgram(programToTest, underPackageManager: Yarn1())
    }

    func testYarn2Works() {
        runProgram(programToTest, underPackageManager: Yarn2())
    }

    func testCargoWorks() {
        runProgram(programToTest, underPackageManager: Cargo())
    }


    static var allTests: [(String, (PackageManagersWork) -> () -> ())] = [
        ("testPipWorks", testPipWorks),
        ("testNpmWorks", testNpmWorks),
        ("testYarn1Works", testYarn1Works),
        ("testYarn2Works", testYarn2Works),
        ("testCargoWorks", testCargoWorks),
    ]
}
