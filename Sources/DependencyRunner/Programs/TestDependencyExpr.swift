let aVersions: [Version] = (0...3).flatMap { major in (0...3).flatMap { minor in (0...3).map { bug in Version(major: major, minor: minor, bug: bug) } } }
let aVersionPublishes: [EcosystemOp] = aVersions.map { .publish(package: "a", version: $0, dependencies: []) }

func testResolve(constraint c: ConstraintExpr) -> EcosystemProgram {
    EcosystemProgram(declaredContexts: ["ctx"], ops: aVersionPublishes + [.solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: c)])])
}

// Same behavior across all 5 package managers
let program_TestC_Exactly = testResolve(constraint: .exactly("1.2.3"))
let program_TestC_Geq = testResolve(constraint: .geq("1.2.3"))
let program_TestC_Gt = testResolve(constraint: .gt("1.2.3"))
let program_TestC_Leq = testResolve(constraint: .leq("1.2.3"))
let program_TestC_Lt = testResolve(constraint: .lt("1.2.3"))
let program_TestC_Tilde = testResolve(constraint: .tilde("1.2.2"))
let program_TestC_WildcardMajor = testResolve(constraint: .wildcardMajor)
let program_TestC_WildcardMinor = testResolve(constraint: .wildcardMinor(1))
let program_TestC_WildcardBug = testResolve(constraint: .wildcardBug(1, 2))

// Unsupported by: pip
let program_TestC_Caret = testResolve(constraint: .caret("1.2.2"))

// Only supported by pip
let program_TestC_NotExactly = testResolve(constraint: .not(.exactly("3.3.3")))
let program_TestC_NotWildcardBug = testResolve(constraint: .not(.wildcardBug(3, 3)))
let program_TestC_NotWildcardMinor = testResolve(constraint: .not(.wildcardMinor(3)))

// Supported by pip, but causes a bug!
// See: https://github.com/pypa/pip/issues/10011
let program_TestC_NotWildcardMajor = testResolve(constraint: .not(.wildcardMajor))
// But this works fine:
let program_TestC_NotExactlyAll = testResolve(constraint: aVersions[1...].reduce(.not(.exactly(aVersions[0]))) { conj, v in .and(conj, .not(.exactly(v))) })


// Unsupported by: pip
let program_TestC_AndRange = testResolve(constraint: .and(.geq("1.2.3"), .leq("2.2.2")))
let program_TestC_AndComplex = testResolve(constraint: .and(.tilde("1.2.3"), .and(.caret("1.2.0"), .gt("1.2.1"))))

// Supported by only: npm, yarn1, yarn2 only
let program_TestC_AndCNF = testResolve(constraint: .and(
                                        .or(.geq("2.2.2"), .leq("1.2.3")),
                                        .or(.geq("1.0.0"), .leq("0.2.3"))))
let program_TestC_OrRange = testResolve(constraint: .or(.geq("2.2.2"), .leq("1.2.3")))

