let program_WeirdCycle = EcosystemProgram(declaredContexts: ["ctx"], ops: [

    .publish(package: "A", version: "1.0.0", dependencies: []),
    .publish(package: "B", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "A", constraint: .geq("1.0.0"), depType: .prod)]),
    .publish(package: "A", version: "2.0.0", dependencies: [DependencyExpr(packageToDependOn: "B", constraint: .geq("1.0.0"), depType: .prod)]),

    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "A", constraint: .any, depType: .prod)])
])

