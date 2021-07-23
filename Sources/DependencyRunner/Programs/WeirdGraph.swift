let program_WeirdGraph = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "A", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "D", constraint: .any)]),
    .publish(package: "B", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "C", constraint: .any)]),
    .publish(package: "C", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "A", constraint: .any), DependencyExpr(packageToDependOn: "D", constraint: .any)]),
    .publish(package: "D", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "B", constraint: .any)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "A", constraint: .any), DependencyExpr(packageToDependOn: "B", constraint: .any)])
])

