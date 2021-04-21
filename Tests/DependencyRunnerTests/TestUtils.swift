import XCTest
@testable import DependencyRunner

func runProgram<R>(_ program: (PackageManager) -> R, underPackageManager p: PackageManager) -> R {
    p.startup()
    let res = program(p)
    p.shutdown()
    return res
}

@discardableResult
func runProgramWithAllPackageManagers(program: (PackageManager) -> SolveResult, funcName: String = #function) -> [SolveResult : Set<String>] {
    let allPackageManagers: [PackageManager] = [Pip(), Npm(), Yarn1(), Yarn2(), Cargo()]
    let resultGroups = allPackageManagers
        .map { (runProgram(program, underPackageManager: $0), $0.uniqueName) }
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
