import XCTest

import dependency_runnerTests

var tests = [XCTestCaseEntry]()
tests += dependency_runnerTests.allTests()
XCTMain(tests)
