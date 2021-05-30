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
    
    func resultAssertions(_ execResult: ExecutionResult<AnyHashable>) {
        let aVersion1Result = SolutionGraph(fromTree: SolutionTree(children: [ResolvedPackage(package: "a", version: "0.0.1", data: 0, children: [])]))
        let aVersion2Result = SolutionGraph(fromTree: SolutionTree(children: [ResolvedPackage(package: "a", version: "0.0.2", data: 0, children: [])]))
        
        let results = assertSuccess(result: execResult)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], aVersion1Result)
        XCTAssertEqual(results[1], aVersion2Result)
    }

    func testPipWorks() {
        resultAssertions(runProgramWithPackageManagers(managerNames: ["pip"], programName: "ManagersWork").keys.first!)
    }

    func testNpmWorks() {
        resultAssertions(runProgramWithPackageManagers(managerNames: ["npm"], programName: "ManagersWork").keys.first!)
    }

    func testYarn1Works() {
        resultAssertions(runProgramWithPackageManagers(managerNames: ["yarn1"], programName: "ManagersWork").keys.first!)
    }

    func testYarn2Works() {
        resultAssertions(runProgramWithPackageManagers(managerNames: ["yarn2"], programName: "ManagersWork").keys.first!)
    }

    func testCargoWorks() {
        resultAssertions(runProgramWithPackageManagers(managerNames: ["cargo"], programName: "ManagersWork").keys.first!)
    }
    
    func testPipRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerNames: ["pip-real"], programName: "ManagersWork").keys.first!)
    }

    func testNpmRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerNames: ["npm-real"], programName: "ManagersWork").keys.first!)
    }
    
    func testYarn1RealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerNames: ["yarn1-real"], programName: "ManagersWork").keys.first!)
    }
    
    func testYarn2RealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerNames: ["yarn2-real"], programName: "ManagersWork").keys.first!)
    }
    
    func testCargoRealWorks() throws {
        try skipTestIfRealRegistriesNotEnabled()
        resultAssertions(runProgramWithPackageManagers(managerNames: ["cargo-real"], programName: "ManagersWork").keys.first!)
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
