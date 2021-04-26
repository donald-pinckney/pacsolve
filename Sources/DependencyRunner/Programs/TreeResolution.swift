let program_TreeResolution = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "b", version: "1.0.2", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.1"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any)])
])
