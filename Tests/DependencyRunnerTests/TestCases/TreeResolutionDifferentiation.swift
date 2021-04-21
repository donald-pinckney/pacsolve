import XCTest
@testable import DependencyRunner

final class TreeResolutionDifferentiation: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func program_testTreeResolutionPrerelease(p: PackageManager) -> SolveResult {
        p.publish(package: "b", version: "0.0.1", dependencies: [])
        p.publish(package: "b", version: "0.0.2", dependencies: [])
        p.publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))])
        
        let ctx = p.makeSolveContext()
        return ctx([DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    }

    func testTreeResolutionPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testTreeResolutionPrerelease)
        
        let npmStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "0.0.1", children: [
                ResolvedPackage(package: "b", version: "0.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "0.0.2", children: [])]))
        
        let pipStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "0.0.1", children: [
                ResolvedPackage(package: "b", version: "0.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "0.0.1", children: [])]))
        
        
        XCTAssertEqual(resultGroups[npmStyleResult], ["npm", "yarn1", "yarn2", "cargo"])
        XCTAssertEqual(resultGroups[pipStyleResult], ["pip"])
    }
    
    
    func program_testTreeResolution(p: PackageManager) -> SolveResult {
        p.publish(package: "b", version: "1.0.1", dependencies: [])
        p.publish(package: "b", version: "1.0.2", dependencies: [])
        p.publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"))])
        
        let ctx = p.makeSolveContext()
        return ctx([DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    }

    func testTreeResolution() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testTreeResolution)
        
        let npmStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "1.0.1", children: [
                ResolvedPackage(package: "b", version: "1.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "1.0.2", children: [])]))
        
        let pipStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "1.0.1", children: [
                ResolvedPackage(package: "b", version: "1.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "1.0.1", children: [])]))
        
        
        XCTAssertEqual(resultGroups[npmStyleResult], ["npm", "yarn1", "yarn2"])
        XCTAssertEqual(resultGroups[pipStyleResult], ["pip", "cargo"])
    }
    
    func program_testVersionCrissCrossPrerelease(p: PackageManager) -> SolveResult {
        p.publish(package: "b", version: "0.0.1", dependencies: [])
        p.publish(package: "b", version: "0.0.2", dependencies: [])
        p.publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"))])
        p.publish(package: "a", version: "0.0.2", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))])
        
        let ctx = p.makeSolveContext()
        return ctx([DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    }
 

    func testVersionCrissCrossPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testVersionCrissCrossPrerelease)
        
        let npmStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "0.0.2", children: [
                ResolvedPackage(package: "b", version: "0.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "0.0.2", children: [])]))
        
        let pipStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "0.0.2", children: [
                ResolvedPackage(package: "b", version: "0.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "0.0.1", children: [])]))
        
        XCTAssertEqual(resultGroups[npmStyleResult], ["npm", "yarn1", "yarn2", "cargo"])
        XCTAssertEqual(resultGroups[pipStyleResult], ["pip"])
    }
    
    
    func program_testVersionCrissCross(p: PackageManager) -> SolveResult {
        p.publish(package: "b", version: "1.0.1", dependencies: [])
        p.publish(package: "b", version: "1.0.2", dependencies: [])
        p.publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.2"))])
        p.publish(package: "a", version: "1.0.2", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"))])
        
        let ctx = p.makeSolveContext()
        return ctx([DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
    }
 

    func testVersionCrissCross() {
        let resultGroups = runProgramWithAllPackageManagers(program: program_testVersionCrissCross)
        
        let npmStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "1.0.2", children: [
                ResolvedPackage(package: "b", version: "1.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "1.0.2", children: [])]))
        
        let pipStyleResult = SolveResult.solveOk(SolutionTree(children: [
            ResolvedPackage(package: "a", version: "1.0.2", children: [
                ResolvedPackage(package: "b", version: "1.0.1", children: [])]),
            ResolvedPackage(package: "b", version: "1.0.1", children: [])]))
        
        XCTAssertEqual(resultGroups[npmStyleResult], ["npm", "yarn1", "yarn2"])
        XCTAssertEqual(resultGroups[pipStyleResult], ["pip", "cargo"])
    }
    


    static var allTests: [(String, (TreeResolutionDifferentiation) -> () -> ())] = [
        ("testTreeResolutionPrerelease", testTreeResolutionPrerelease),
        ("testTreeResolution", testTreeResolution),
        ("testVersionCrissCrossPrerelease", testVersionCrissCrossPrerelease),
        ("testVersionCrissCross", testVersionCrissCross),
    ]
}
