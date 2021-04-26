let program_CrissCrossPre = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "b", version: "0.0.2", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"))]),
    .publish(package: "a", version: "0.0.2", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
])
