let program_WeirdGraph = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "A", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "D", constraint: .any, depType: .prod)]),
    .publish(package: "B", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "C", constraint: .any, depType: .prod)]),
    .publish(package: "C", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "A", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "D", constraint: .any, depType: .prod)]),
    .publish(package: "D", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "B", constraint: .any, depType: .prod)]),
    .publish(package: "E", version: "1.0.0", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "A", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "B", constraint: .any, depType: .prod)])
])

