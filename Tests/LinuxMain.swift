import XCTest

import DependencyRunnerTests

var tests = [XCTestCaseEntry]()
tests += DependencyRunnerTests.allTests()
XCTMain(tests)
