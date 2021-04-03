import XCTest
import class Foundation.Bundle
@testable import DependencyRunner

final class DependencyRunnerTests: XCTestCase { 
    
//    func testPipWorks() {
////        let mainPkg = MainPackage()
////        let a = Package(name: "a", versions: ["0.0.1"])
////        let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])
//
//        let eco = Ecosystem(
//            "a": [
//                "0.0.1": [DependencyExpr()],
//                ...
//            ],
//            "b": [
//                ...
//            ],
//            "__main_pkg__": [
//                "0.1.0": [
//                    any("a") && any("b")
//                ]
//            ]
//        )
//
//        eco.solve(forPackage: "__main_pkg__", usingDependencyManagers: [Pip()])
//
//
//
////        let resultGroups = runTest(dependencies: deps, usingPackageManagers: [Pip()])
////        assert(resultGroups, hasPartitions: [
////            ["pip"]
////        ])
//    }
//
//
//
//
//    func testNpmWorks() {
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
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: [Npm()])
//        assert(resultGroups, hasPartitions: [
//            ["npm"]
//        ])
//    }
//
//    func testYarn1Works() {
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
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: [Yarn1()])
//        assert(resultGroups, hasPartitions: [
//            ["yarn1"]
//        ])
//    }
//
//    func testYarn2Works() {
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
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: [Yarn2()])
//        assert(resultGroups, hasPartitions: [
//            ["yarn2"]
//        ])
//    }
//
//    func testCargoWorks() {
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
//        let resultGroups = runTest(dependencies: deps, usingPackageManagers: [Cargo()])
//        assert(resultGroups, hasPartitions: [
//            ["cargo"]
//        ])
//    }
//
//
//
//
//
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
