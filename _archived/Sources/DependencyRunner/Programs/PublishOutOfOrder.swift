let program_PublishOutOfOrderBug = EcosystemProgram(declaredContexts: ["ctx1", "ctx2"], ops: [
    .publish(package: "a", version: "0.0.4", dependencies: []),
    .publish(package: "a", version: "0.0.3", dependencies: []),
    .publish(package: "a", version: "0.0.5", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .solve(inContext: "ctx1", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .leq("0.0.5"), depType: .prod)]),
    .solve(inContext: "ctx2", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .gt("0.0.1"), depType: .prod)])
])

/*
 ["cargo-real", "yarn2-real", "pip-real"]
 success([success(a v0.0.5)])

 ["npm-real", "yarn1-real"]
 success([success(a v0.0.1)])
 */



let program_PublishOutOfOrderMinor = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.1.1", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

let program_PublishOutOfOrderMinorBug = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.1.1", dependencies: []),
    .publish(package: "a", version: "0.1.0", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

let program_PublishOutOfOrderMajor = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "2.0.0", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
])

/*
 ["yarn2-real", "cargo-real", "pip-real"]
 success([success(a v2.0.0)])

 ["npm-real", "yarn1-real"]
 success([success(a v1.0.1)])
 */
