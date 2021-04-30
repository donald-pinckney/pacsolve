let program_FreshExactDepOnYank = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .yank(package: "a", version: "0.0.2"),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("0.0.2"))])
])

/*
 ["pip-real", "npm-real"]
 SOLVE succeeds with a@0.0.2
 
 ["cargo-real"]
 SOLVE error: version 0.0.1 doesn't match ==0.0.2
 */



let program_FreshAnyDepOnYank = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .yank(package: "a", version: "0.0.2"),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])

/*
 ["pip-real", "cargo-real"]
 SOLVE succeeds with a@0.0.1
 
 ["npm-real"]
 SOLVE succeeds with a@0.0.2
 */



let program_SolveYankSolve = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)]),
    .yank(package: "a", version: "0.0.2"),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)]),
])

/*
 ["pip-real", "npm-real", "cargo-real"]
 Both solves succeed with a@0.0.2
 */

