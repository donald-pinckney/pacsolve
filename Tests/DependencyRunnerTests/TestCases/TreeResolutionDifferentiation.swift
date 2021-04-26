import XCTest
@testable import DependencyRunner

final class TreeResolutionDifferentiation: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    
    

    func testTreeResolutionPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "TreeResolutionPre")
        
        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.2", children: [])
            ]))
        ]
        
        let pipStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.1", children: [])
            ]))
        ]
        
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names() + cargoNames())
        XCTAssertEqual(resultGroups[pipStyleResult], pipNames())
    }
    
    
    
    

    func testTreeResolution() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "TreeResolution")

        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.2", children: [])
            ]))
        ]
        
        let pipStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.1", children: [])
            ]))
        ]
        
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names())
        XCTAssertEqual(resultGroups[pipStyleResult], pipNames() + cargoNames())
    }
    
    
 

    func testVersionCrissCrossPrerelease() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "CrissCrossPre")

        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.2", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.2", children: [])
            ]))
        ]
        
        let crossChoice1 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.2", children: [
                    ResolvedPackage(package: "b", version: "0.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.1", children: [])
            ]))
        ]
        
        let crossChoice2 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "0.0.1", children: [
                    ResolvedPackage(package: "b", version: "0.0.2", children: [])
                ]),
                ResolvedPackage(package: "b", version: "0.0.2", children: [])
            ]))
        ]
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names() + cargoNames())
        XCTAssertEqual(resultGroups[crossChoice1, default: Set()].union(resultGroups[crossChoice2, default: Set()]), pipNames())

    }
    
    
    
    
    func testVersionCrissCross() {
        let resultGroups = runProgramWithAllPackageManagers(programName: "CrissCross")

        let npmStyleResult = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.2", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.2", children: [])
            ]))
        ]
        
        let crossChoice1 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.2", children: [
                    ResolvedPackage(package: "b", version: "1.0.1", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.1", children: [])
            ]))
        ]
        
        let crossChoice2 = [
            SolveResult.solveOk(SolutionTree(children: [
                ResolvedPackage(package: "a", version: "1.0.1", children: [
                    ResolvedPackage(package: "b", version: "1.0.2", children: [])
                ]),
                ResolvedPackage(package: "b", version: "1.0.2", children: [])
            ]))
        ]
        
        XCTAssertEqual(resultGroups[npmStyleResult], npmNames() + yarn1Names() + yarn2Names())
                
        // NOTE: This is really interesting! Cargo will choose one of the two crossChoice(1/2)
        // based on the lexical ordering of the clobbered name of a vs. b.
        // But it seems that pip will always choose crossChoice1. Not too sure, need to investigate more
        XCTAssertEqual(resultGroups[crossChoice1, default: Set()].union(resultGroups[crossChoice2, default: Set()]), pipNames() + cargoNames())
    }
    


    static var allTests: [(String, (TreeResolutionDifferentiation) -> () -> ())] = [
        ("testTreeResolutionPrerelease", testTreeResolutionPrerelease),
        ("testTreeResolution", testTreeResolution),
        ("testVersionCrissCrossPrerelease", testVersionCrissCrossPrerelease),
        ("testVersionCrissCross", testVersionCrissCross),
    ]
}
