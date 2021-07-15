let program_Transitive = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "c", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "c", constraint: .any)]),
    .publish(package: "a", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .any)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])

