let program_ShareNode = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .any)]),
    .solve(inContext: "ctx", constraints: [
            DependencyExpr(packageToDependOn: "a", constraint: .any),
            DependencyExpr(packageToDependOn: "b", constraint: .any)]),
])
