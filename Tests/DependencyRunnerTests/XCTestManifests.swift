import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MaximizeVersionNumbers.allTests),
        testCase(MinimizeNumberDependencies.allTests),
        testCase(PackageManagersWork.allTests),
        testCase(TreeResolutionDifferentiation.allTests),
    ]
}
#endif
