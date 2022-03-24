let program_AllThreeDifferent = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "b", version: "2.0.1", dependencies: []),
    .publish(package: "b", version: "2.0.2", dependencies: []),

    .publish(package: "a", version: "1.0.1", dependencies: [
        DependencyExpr(packageToDependOn: "b", constraint: .exactly("2.0.2"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [
        DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod), 
        DependencyExpr(packageToDependOn: "b", constraint: .lt("2.0.2"), depType: .prod)])
])
