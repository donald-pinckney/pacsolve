import XCTest
@testable import DependencyRunner

final class PackageManagersWork: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    let programToTest = EcosystemProgram(declaredContexts: ["ctx1", "ctx2"], ops: [
        .publish(package: "a", version: "0.0.1", dependencies: []),
        .solve(inContext: "ctx1", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)]),
        .publish(package: "a", version: "0.0.2", dependencies: []),
        .solve(inContext: "ctx2", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)]),
    ])
    
    func resultAssertions(_ results: [SolveResult]) {        
        let aVersion1Result = SolveResult.solveOk(SolutionTree(children: [ResolvedPackage(package: "a", version: "0.0.1", children: [])]))
        let aVersion2Result = SolveResult.solveOk(SolutionTree(children: [ResolvedPackage(package: "a", version: "0.0.2", children: [])]))
        
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], aVersion1Result)
        XCTAssertEqual(results[1], aVersion2Result)
    }

    func testPipWorks() {
        resultAssertions(programToTest.run(underPackageManager: Pip()))
    }

    func testNpmWorks() {
        resultAssertions(programToTest.run(underPackageManager: Npm()))
    }

    func testYarn1Works() {
        resultAssertions(programToTest.run(underPackageManager: Yarn1()))
    }

    func testYarn2Works() {
        resultAssertions(programToTest.run(underPackageManager: Yarn2()))
    }

    func testCargoWorks() {
        resultAssertions(programToTest.run(underPackageManager: Cargo()))
    }
    
    func testPipRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(programToTest.run(underPackageManager: PipReal()))
    }

    func testNpmRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(programToTest.run(underPackageManager: NpmReal()))
    }
    
    func testYarn1RealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(programToTest.run(underPackageManager: Yarn1Real()))
    }
    
    func testYarn2RealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(programToTest.run(underPackageManager: Yarn2Real()))
    }
    
    func testCargoRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(programToTest.run(underPackageManager: CargoReal()))
    }

    static var allTests: [(String, (PackageManagersWork) -> () -> ())] = [
        ("testPipWorks", testPipWorks),
        ("testNpmWorks", testNpmWorks),
        ("testYarn1Works", testYarn1Works),
        ("testYarn2Works", testYarn2Works),
        ("testCargoWorks", testCargoWorks),
    ]
}
