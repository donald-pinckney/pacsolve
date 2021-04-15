import XCTest
@testable import DependencyRunner

final class TreeResolutionDifferentiation: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTreeResolutionPrerelease() {
        let ecosystem = Ecosystem([
            "m": [
                "0.0.1": [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)],
            ],
            "a": [
                "0.0.1": [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))],
            ],
            "b" : [
                "0.0.1": [],
                "0.0.2": []
            ]
        ])

        let resultGroups = solveEcosystemWithAllPackageManagers(ecosystem: ecosystem, forRootPackage: "m", version: "0.0.1")
        assert(resultGroups, hasPartitions: [
            ["npm", "yarn1", "yarn2", "cargo"],
            ["pip"]
        ])
    }


    func testTreeResolution() {
        let ecosystem = Ecosystem([
            "m": [
                "0.0.1": [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)],
            ],
            "a": [
                "1.0.1": [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"))],
            ],
            "b" : [
                "1.0.1": [],
                "1.0.2": []
            ]
        ])

        let resultGroups = solveEcosystemWithAllPackageManagers(ecosystem: ecosystem, forRootPackage: "m", version: "0.0.1")
        assert(resultGroups, hasPartitions: [
            ["npm", "yarn1", "yarn2"],
            ["pip", "cargo"]
        ])
    }




    func testVersionCrissCrossPrerelease() {
        let ecosystem = Ecosystem([
            "m": [
                "0.0.1": [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)],
            ],
            "a": [
                "0.0.1": [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"))],
                "0.0.2": [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))],
            ],
            "b" : [
                "0.0.1": [],
                "0.0.2": []
            ]
        ])

        let resultGroups = solveEcosystemWithAllPackageManagers(ecosystem: ecosystem, forRootPackage: "m", version: "0.0.1")
        assert(resultGroups, hasPartitions: [
            ["npm", "yarn1", "yarn2", "cargo"],
            ["pip"]
        ])
    }

    func testVersionCrissCross() {
        let ecosystem = Ecosystem([
            "m": [
                "0.0.1": [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)],
            ],
            "a": [
                "1.0.1": [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.2"))],
                "1.0.2": [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"))],
            ],
            "b" : [
                "1.0.1": [],
                "1.0.2": []
            ]
        ])
        

        let resultGroups = solveEcosystemWithAllPackageManagers(ecosystem: ecosystem, forRootPackage: "m", version: "0.0.1")
        assert(resultGroups, hasPartitions: [
            ["npm", "yarn1", "yarn2"],
            ["pip", "cargo"]
        ])
    }

    static var allTests = [
        ("testTreeResolutionPrerelease", testTreeResolutionPrerelease),
        ("testTreeResolution", testTreeResolution),
        ("testVersionCrissCrossPrerelease", testVersionCrissCrossPrerelease),
        ("testVersionCrissCross", testVersionCrissCross),
    ]
}
