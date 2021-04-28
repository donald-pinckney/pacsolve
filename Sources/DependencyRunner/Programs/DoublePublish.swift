let program_DoublePublish = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])

/*
 ["npm-real", "yarn1-real", "yarn2-real", "cargo-real", "pip-real"]
 ERROR on 2nd publish

 */

