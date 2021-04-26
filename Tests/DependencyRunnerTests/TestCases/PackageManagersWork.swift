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
        resultAssertions(runProgramWithPackageManagers(managerInits: [Pip], programName: "ManagersWork").keys.first!)
    }

    func testNpmWorks() {
        resultAssertions(runProgramWithPackageManagers(managerInits: [Npm], programName: "ManagersWork").keys.first!)
    }

    func testYarn1Works() {
        resultAssertions(runProgramWithPackageManagers(managerInits: [Yarn1], programName: "ManagersWork").keys.first!)
    }

    func testYarn2Works() {
        resultAssertions(runProgramWithPackageManagers(managerInits: [Yarn2], programName: "ManagersWork").keys.first!)
    }

    func testCargoWorks() {
        resultAssertions(runProgramWithPackageManagers(managerInits: [Cargo.init], programName: "ManagersWork").keys.first!)
    }
    
    func testPipRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerInits: [PipReal], programName: "ManagersWork").keys.first!)
    }

    func testNpmRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerInits: [NpmReal], programName: "ManagersWork").keys.first!)
    }
    
    func testYarn1RealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerInits: [Yarn1Real], programName: "ManagersWork").keys.first!)
    }
    
    func testYarn2RealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerInits: [Yarn2Real], programName: "ManagersWork").keys.first!)
    }
    
    func testCargoRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerInits: [CargoReal], programName: "ManagersWork").keys.first!)
    }

    static var allTests: [(String, (PackageManagersWork) -> () throws -> ())] = [
        ("testPipWorks", testPipWorks),
        ("testNpmWorks", testNpmWorks),
        ("testYarn1Works", testYarn1Works),
        ("testYarn2Works", testYarn2Works),
        ("testCargoWorks", testCargoWorks),
        ("testPipRealWorks", testPipRealWorks),
        ("testNpmRealWorks", testNpmRealWorks),
        ("testYarn1RealWorks", testYarn1RealWorks),
        ("testYarn2RealWorks", testYarn2RealWorks),
        ("testCargoRealWorks", testCargoRealWorks),
    ]
}
