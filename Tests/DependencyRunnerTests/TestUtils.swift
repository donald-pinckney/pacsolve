import XCTest
@testable import DependencyRunner


@discardableResult
func solveEcosystemWithAllPackageManagers(ecosystem: Ecosystem, forRootPackage root: Package, version v: Version, funcName: String = #function) -> [SolveResult : Set<String>] {
    let allPackageManagers: [PackageManager] = [Pip(), Npm(), Yarn1(), Yarn2(), Cargo()]
    let resultGroups = allPackageManagers
        .map { ($0.solve(ecosystem, forRootPackage: root, version: v), $0.uniqueName) }
        .reduce(into: [:]) { ( groups: inout [SolveResult : Set<String>], result_name) in
            let (result, name) = result_name
            groups[result, default: []].insert(name)
        }
    
    
    print("Test \(funcName) results:")
    for (result, group) in resultGroups {
        print(group)
        print(result)
        print()
    }
    print("------------------------------------\n\n")

    return resultGroups
}

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
