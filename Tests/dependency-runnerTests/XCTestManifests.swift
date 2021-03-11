import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(dependency_runnerTests.allTests),
    ]
}
#endif
