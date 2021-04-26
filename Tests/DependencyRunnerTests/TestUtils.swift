import XCTest
import Foundation
@testable import DependencyRunner


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

//extension Dictionary {
//    func keyMap<K>(unit: Value, monoidOp: (Value) -> (Value) -> Value, keyMap: (Key) -> K) -> [K : Value] {
//        var result: [K : Value] = [:]
//
//        for (k, v) in self {
//            let newK = keyMap(k)
//            result[newK] = monoidOp(result[newK, default: unit])(v)
//        }
//
//        return result
//    }
//}



func skipTestIfRealRegistriesNotEnabled(file: StaticString = #filePath, line: UInt = #line) throws {
    try XCTSkipUnless(shouldRunReal(), "Skipping running real registries. Enable using ENABLE_REAL_REGISTRIES=true ...", file: file, line: line)
}


fileprivate func managerNames(localName: String) -> Set<String> {
    [localName] + (shouldRunReal() ? [localName + "-real"] : [])
}

func pipNames() -> Set<String> {
    managerNames(localName: "pip")
}
func npmNames() -> Set<String> {
    managerNames(localName: "npm")
}
func yarn1Names() -> Set<String> {
    managerNames(localName: "yarn1")
}
func yarn2Names() -> Set<String> {
    managerNames(localName: "yarn2")
}
func cargoNames() -> Set<String> {
    managerNames(localName: "cargo")
}

func +<T>(x: Set<T>, y: Set<T>) -> Set<T> {
    x.union(y)
}
