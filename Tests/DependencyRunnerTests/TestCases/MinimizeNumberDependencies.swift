import XCTest
@testable import DependencyRunner

final class MinimizeNumberDependencies: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    let program_testObviousSingleResolutionPrerelease = EcosystemProgram(declaredContexts: ["ctx"], ops: [
        .publish(package: "b", version: "0.0.1", dependencies: []),
        .publish(package: "b", version: "0.0.2", dependencies: []),
        .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"))]),
        .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    ])

    func testObviousSingleResolutionPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testObviousSingleResolutionPrerelease)
        
        let correctResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", children: [
                    ResolvedPackage(package: "b", version: "0.0.2", children: [])]),
                ResolvedPackage(package: "b", version: "0.0.2", children: [])]))
        ]
        
        XCTAssertEqual(resultGroups[correctResult], npmNames() + yarn1Names() + yarn2Names() + pipNames() + cargoNames())
    }
    
    
    let program_testObviousSingleResolution = EcosystemProgram(declaredContexts: ["ctx"], ops: [
        .publish(package: "b", version: "1.0.1", dependencies: []),
        .publish(package: "b", version: "1.0.2", dependencies: []),
        .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.2"))]),
        .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    ])

    func testObviousSingleResolution() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testObviousSingleResolution)
        
        let correctResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", children: [
                    ResolvedPackage(package: "b", version: "1.0.2", children: [])]),
                ResolvedPackage(package: "b", version: "1.0.2", children: [])
            ]))
        ]
        
        XCTAssertEqual(resultGroups[correctResult], npmNames() + yarn1Names() + yarn2Names() + pipNames() + cargoNames())
    }

    static var allTests: [(String, (MinimizeNumberDependencies) -> () -> ())] = [
        ("testObviousSingleResolutionPrerelease", testObviousSingleResolutionPrerelease),
        ("testObviousSingleResolution", testObviousSingleResolution),
    ]
}
