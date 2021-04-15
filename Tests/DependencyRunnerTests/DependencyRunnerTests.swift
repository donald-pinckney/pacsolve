import XCTest
import class Foundation.Bundle
@testable import DependencyRunner

final class DependencyRunnerTests: XCTestCase {
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





//    func testTreeResolutionPrerelease() {
//        let mainPkg = MainPackage()
//        let a = Package(name: "a", versions: ["0.0.1"])
//        let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])
//
//        let deps = dependencies(
//            mainPkg.dependsOn(
//                a.any(),
//                b.any()
//            ),
//            a.version("0.0.1").dependsOn(
//                b == "0.0.1"
//            )
//        )
//
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
//        assert(resultGroups, hasPartitions: [
//            ["npm", "yarn1", "yarn2", "cargo"],
//            ["pip"]
//        ])
//    }
//
//
//    func testTreeResolution() {
//        let mainPkg = MainPackage()
//        let a = Package(name: "a", versions: ["1.0.1"])
//        let b = Package(name: "b", versions: ["1.0.1", "1.0.2"])
//
//        let deps = dependencies(
//            mainPkg.dependsOn(
//                a.any(),
//                b.any()
//            ),
//            a.version("1.0.1").dependsOn(
//                b == "1.0.1"
//            )
//        )
//
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
//        assert(resultGroups, hasPartitions: [
//            ["cargo", "pip"],
//            ["npm", "yarn1", "yarn2"]
//        ])
//    }
//
//
//
//
//    func testVersionCrissCrossPrerelease() {
//        let mainPkg = MainPackage()
//        let a = Package(name: "a", versions: ["0.0.1", "0.0.2"])
//        let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])
//
//        let deps = dependencies(
//            mainPkg.dependsOn(
//                a.any(),
//                b.any()
//            ),
//            a.version("0.0.1").dependsOn(
//                b == "0.0.2"
//            ),
//            a.version("0.0.2").dependsOn(
//                b == "0.0.1"
//            )
//        )
//
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
//        assert(resultGroups, hasPartitions: [
//            ["npm", "yarn1", "yarn2", "cargo"],
//            ["pip"]
//        ])
//    }
//
//    func testVersionCrissCross() {
//        let mainPkg = MainPackage()
//        let a = Package(name: "a", versions: ["1.0.1", "1.0.2"])
//        let b = Package(name: "b", versions: ["1.0.1", "1.0.2"])
//
//        let deps = dependencies(
//            mainPkg.dependsOn(
//                a.any(),
//                b.any()
//            ),
//            a.version("1.0.1").dependsOn(
//                b == "1.0.2"
//            ),
//            a.version("1.0.2").dependsOn(
//                b == "1.0.1"
//            )
//        )
//
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
//        assert(resultGroups, hasPartitions: [
//            ["npm", "yarn1", "yarn2"],
//            ["pip", "cargo"]
//        ])
//    }
//
//
//
//
//
//
//
//
//
//
//
//
//    func testAnyVersionMax() {
//        let mainPkg = MainPackage()
//        let a = Package(name: "a", versions: ["0.0.1", "0.0.2", "0.1.0", "0.1.1", "0.1.2", "1.0.0", "1.0.1", "2.0.0", "2.0.1", "2.1.0"])
//
//        let deps = dependencies(
//            mainPkg.dependsOn(
//                a.any()
//            )
//        )
//
//        runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
//    }
//
//
//
//
//
//
//    func testObviousSingleResolutionPrerelease() {
//        let mainPkg = MainPackage()
//        let a = Package(name: "a", versions: ["0.0.1"])
//        let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])
//
//        let deps = dependencies(
//            mainPkg.dependsOn(
//                a.any(),
//                b.any()
//            ),
//            a.version("0.0.1").dependsOn(
//                b == "0.0.2"
//            )
//        )
//
//        runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
//    }
//
//    func testObviousSingleResolution() {
//        let mainPkg = MainPackage()
//        let a = Package(name: "a", versions: ["1.0.1"])
//        let b = Package(name: "b", versions: ["1.0.1", "1.0.2"])
//
//        let deps = dependencies(
//            mainPkg.dependsOn(
//                a.any(),
//                b.any()
//            ),
//            a.version("1.0.1").dependsOn(
//                b == "1.0.2"
//            )
//        )
//
//        runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
//    }
//
//
//    static var allTests = [
//        ("testPipWorks", testPipWorks),
//        ("testNpmWorks", testNpmWorks),
//        ("testYarn1Works", testYarn1Works),
//        ("testYarn2Works", testYarn2Works),
//        ("testCargoWorks", testCargoWorks),
//
//        ("testTreeResolutionPrerelease", testTreeResolutionPrerelease),
//        ("testTreeResolution", testTreeResolution),
//        ("testVersionCrissCrossPrerelease", testVersionCrissCrossPrerelease),
//        ("testVersionCrissCross", testVersionCrissCross),
//        ("testAnyVersionMax", testAnyVersionMax),
//        ("testObviousSingleResolutionPrerelease", testObviousSingleResolutionPrerelease),
//        ("testObviousSingleResolution", testObviousSingleResolution),
//    ]
}


//@discardableResult
//func runTest(dependencies: Dependencies, usingPackageManagers: [PackageManager], name: String = #function) -> [SolveResult : Set<String>] {
//    let resultGroups = dependencies.solve(usingPackageManagers: usingPackageManagers)
//
//    print("Test \(name) results:")
//    for (result, group) in resultGroups {
//        print(group)
//        print(result)
//        print()
//    }
//    print("\n\n------------------------------------\n\n")
//
//    return resultGroups
//}

func assert(_ resultGroups: [SolveResult : Set<String>], hasPartitions: Set<Set<String>>) {
    let givenPartitions = Set(resultGroups.values)
    assert(givenPartitions == hasPartitions)
}

func assertOk(result: SolveResult, message: String = "", file: StaticString = #filePath, line: UInt = #line) -> SolutionTree {
    switch result {
    case .solveError(let err):
        XCTFail("Solve error: \(err)\n\(message)")
        fatalError() // unreachable
    case .solveOk(let tree): return tree
    }
}
