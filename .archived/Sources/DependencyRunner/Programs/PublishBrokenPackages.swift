
let program_PublishWithNonexistentDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

/*
 ["pip-real", "npm-real"]
 Publish SUCCESS, solve FAIL

 ["cargo-real"]
 Publish FAIL
 */



let program_PublishWithYankedDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "b", version: "0.0.2", dependencies: []),
    .yank(package: "b", version: "0.0.1"),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

/*
 ["pip-real", "npm-real"]
 Solve success (a@0.0.1, b@0.0.1)

 ["cargo-real"]
 Solve FAIL
 */



let program_PublishThenYankDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"), depType: .prod)]),
    .yank(package: "b", version: "0.0.1"),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])


let program_PublishWithNonexistentDepVersion = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

/*
 ["pip-real", "npm-real", "cargo-real"]
 Publishes SUCCEED, solve FAILS
 */



let program_PublishSelfDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("0.0.1"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

/*
 ["pip-real", "npm-real"]
 SOLVE succeeds with a@0.0.1. Imports also work, but the tree-printing recursion stack overflows. TODO: fix this
 
 ["cargo-real"]
 SOLVE error: cargo detects the cycle
 */



let program_Publish2Cycle = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"), depType: .prod)]),
    .publish(package: "b", version: "0.0.2", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("0.0.2"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

/*
 ["pip-real", "npm-real"]
 SOLVE succeeds with a@0.0.2 and b@0.0.2. Imports also work, but the tree-printing recursion stack overflows. TODO: fix this
 
 ["cargo-real"]
 SOLVE error: cargo detects the cycle
 */


let program_PublishOldVersionSelfCycle = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("0.0.1"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("0.0.2"), depType: .prod)])
])

/*
 ["pip-real"]
 SOLVE fails since pip can't have a@0.0.2 and a@0.0.1
 
 ["npm-real", "cargo-real"]
 SOLVE succeeds with a@0.0.2 and a@0.0.1.
 */

