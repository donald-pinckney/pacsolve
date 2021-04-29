let program_FreshExactDepOnYank = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .yank(package: "a", version: "0.0.2"),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("0.0.2"))])
])

/*
 ["pip-real", "npm-real"]
 SOLVE succeeds with a@0.0.1. Imports also work, but the tree-printing recursion stack overflows. TODO: fix this
 
 ["cargo-real"]
 SOLVE error: cargo detects the cycle
 */



//let program_FreshAnyDepOnYank = EcosystemProgram(declaredContexts: ["ctx"], ops: [
//    .publish(package: "a", version: "0.0.1", dependencies: []),
//    .publish(package: "a", version: "0.0.2", dependencies: []),
//    .yank(package: "a", version: "0.0.2"),
//    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
//])
