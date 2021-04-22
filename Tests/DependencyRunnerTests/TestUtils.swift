import XCTest
@testable import DependencyRunner

@discardableResult
func runProgramWithAllPackageManagers(program: EcosystemProgram, funcName: String = #function) -> [[SolveResult] : Set<String>] {
    let allPackageManagers: [PackageManager] = [Pip(), Npm(), Yarn1(), Yarn2(), Cargo()]
    let resultGroups = allPackageManagers
        .map { (program.run(underPackageManager: $0), $0.uniqueName) }
        .reduce(into: [:]) { ( groups: inout [[SolveResult] : Set<String>], result_name) in
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


func assert<K>(_ resultGroups: [K : Set<String>], hasPartitions: Set<Set<String>>) {
    let givenPartitions = Set(resultGroups.values)
    
//    resultGroups
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

extension Dictionary {
    func keyMap<K>(unit: Value, monoidOp: (Value) -> (Value) -> Value, keyMap: (Key) -> K) -> [K : Value] {
        var result: [K : Value] = [:]
        
        for (k, v) in self {
            let newK = keyMap(k)
            result[newK] = monoidOp(result[newK, default: unit])(v)
        }
        
        return result
    }
}

