import XCTest
import Foundation
@testable import DependencyRunner


func assert<K>(_ resultGroups: [K : Set<String>], hasPartitions: Set<Set<String>>) {
    let givenPartitions = Set(resultGroups.values)
    
//    resultGroups
    assert(givenPartitions == hasPartitions)
}



func assertSuccess<V, E>(result: Result<V, E>, message: String = "", file: StaticString = #filePath, line: UInt = #line) -> V {
    switch result {
    case .failure(let err):
        XCTFail("Error: \(err)\n\(message)")
        fatalError() // unreachable
    case .success(let tree): return tree
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
    var ns = Set([localName])
    if shouldRunReal() {
        ns.insert(localName + "-real")
    }
    return ns    
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
