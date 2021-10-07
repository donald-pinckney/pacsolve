let program_ShareNode = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)]),
    .solve(inContext: "ctx", constraints: [
            DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod),
            DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod)]),
])
